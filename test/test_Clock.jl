println("... basic tests: only events  ...")
s = Sim.SimEvent(:(1+1), Main, 10, 0)
@test eval(s.ex) == 2
@test s.t == 10

sim = Clock()  # set up clock without sampling
@test_warn "undefined transition" Sim.step!(sim, sim.state, Sim.Resume())
@test init!(sim) == Sim.Idle()
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

@test Sim.nextevent(sim).t == 100

incr!(sim)
@test now(sim) == 100
@test a == 1
@test Sim.nextevent(sim).t == 101

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

println("... basic tests: only sampling ...")
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

println("... basic tests: events and sampling ...")
function foo()
    global a += 1
    event!(sim, :(foo()), after, rand())
end
function bar()
    global b += 1
end
a = 0
b = 0
sim = Clock(0.5)
event!(sim, :(foo()), at, 0.5)
event!(sim, :(foo()), at, 1)
sample!(sim, :(bar()))
run!(sim, 10000)
@test a == sim.evcount
@test b == 20000

println("... basic tests with SimFunction ...")
D = Dict(:a=>0, :b=>0, :c=>0)
function f!(D, i)
    D[:a] += 1
    D[:b] = D[:a]^2
    D[:c] = D[:a]^3
end
sim = Clock()
event!(sim, SimFunction(f!, D, 1), every, 1)
run!(sim, 20)
@test D[:a] == 21
@test D[:b] == 21^2
@test D[:c] == 21^3
