println("... basic tests without sampling ...")
s = Sim.SimEvent(:(1+1), Main, 10, 0)
@test eval(s.expr) == 2
@test s.t == 10

sim = Clock()  # set up clock without sampling
@test now(sim) == 0
sim = Clock(t0=100)
@test now(sim) == 100
@test_warn "nothing to evaluate" incr!(sim)

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

incr!(sim)
@test now(sim) == 100
@test a == 1

run!(sim, 5)
@test now(sim) == 105
@test a == 11
@test length(sim.events) == 6
stop = event!(sim, :(stop!(sim)), 108)
run!(sim, 6)
@test a == 16
@test sim.state == Sim.Halted()
@test now(sim) == stop
resume!(sim)
@test now(sim) == 111
@test a == 22
@test length(sim.events) == 1

t = 121.0
for i ∈ 1:10
    _t = event!(sim, :(a += 1), 10 + now(sim))
    @test t == _t
    global t = nextfloat(_t)
end
run!(sim,14)
@test now(sim) == 125
@test a == 46
@test length(sim.events) == 1

println("... basic tests with sampling ...")
sim = Clock(1)  # clock with sample rate 1
@test sim.time == 0
@test sim.tsa == 1
@test sim.Δt == 1

b = 0
sample!(sim, :(b += 1))
@test length(sim.sexpr) == 1
incr!(sim)
@test sim.time == 1
@test b == 1
run!(sim, 9)
@test sim.time == 10
@test b == 10
sample_time!(sim, 0.5)
run!(sim, 10)
@test sim.time == 20
@test b == 30
