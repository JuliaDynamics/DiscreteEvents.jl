s = Sim.SimEvent(:(1+1), Main, 10)
@test eval(s.expr) == 2
@test s.at == 10

sim = Clock()
@test now(sim) == 0
sim = Clock(100)
@test now(sim) == 100
@test_warn "no event" step!(sim)

a = 0

for i ∈ 1:10
    at = i + now(sim)
    @test event!(sim, :(a += 1), at) == at
end

@test length(sim.events) == 10

step!(sim)
@test now(sim) == 101
@test a == 1

run!(sim, 4)
@test now(sim) == 105
@test a == 5
@test length(sim.events) == 5
stop = event!(sim, :(stop!(sim)), 108)
run!(sim, 6)
@test a == 8
@test sim.state == Sim.Halted()
@test now(sim) == stop
resume!(sim)
@test now(sim) == 111
@test a == 10
@test isempty(sim.events)

at = 121.0
for i ∈ 1:10
    t = event!(sim, :(a += 1), 10 + now(sim))
    @test t == at
    global at = nextfloat(at)
end
run!(sim,14)
@test now(sim) == 125
@test a == 20
@test isempty(sim.events)
