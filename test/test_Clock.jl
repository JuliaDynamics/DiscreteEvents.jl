s = Sim.SimEvent(:(1+1), Main, 10, 0)
@test eval(s.expr) == 2
@test s.t == 10

sim = Clock()
@test now(sim) == 0
sim = Clock(100)
@test now(sim) == 100
@test_warn "no event" step!(sim)

a = 0

for i ∈ 1:4
    t = i + now(sim)
    @test event!(sim, :(a += 1), t) == t
end

for i ∈ 5:7
    t = i + now(sim)
    @test event!(sim, :(a += 1), at, t) == t
end

for i ∈ 8:10
    @test event!(sim, :(a += 1), after, i) == 100+i
end

@test event!(sim, :(a += 1), every, 1) == 100

@test length(sim.events) == 11

step!(sim)
@test now(sim) == 100
@test a == 1

run!(sim, 5)
@test now(sim) == 105
@test a == 10
@test length(sim.events) == 6
stop = event!(sim, :(stop!(sim)), 108)
run!(sim, 6)
@test a == 16
@test sim.state == Sim.Halted()
@test now(sim) == stop
resume!(sim)
@test now(sim) == 111
@test a == 21
@test length(sim.events) == 1

t = 121.0
for i ∈ 1:10
    _t = event!(sim, :(a += 1), 10 + now(sim))
    @test t == _t
    global t = nextfloat(_t)
end
run!(sim,14)
@test now(sim) == 125
@test a == 45
@test length(sim.events) == 1
