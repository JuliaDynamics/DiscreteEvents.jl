println("... basic tests: only events  ...")
reset!(𝐶)
@test τ() == 0
@test_warn "undefined transition" Sim.step!(𝐶, 𝐶.state, Sim.Resume())

ev = Sim.SimEvent(:(1+1), Main, 10, 0)
@test eval(ev.ex) == 2
@test ev.t == 10

sim = Clock()  # set up clock without sampling
@test_warn "undefined transition" Sim.step!(sim, sim.state, Sim.Resume())
init!(sim)
@test sim.state == Sim.Idle()
@test τ(sim) == 0
sim = Clock(t0=100)
@test τ(sim) == 100
@test_warn "nothing to evaluate" incr!(sim)

a = 0

for i ∈ 1:4
    t = i + τ(sim)
    @test event!(sim, :(a += 1), t) == t
end

for i ∈ 5:7
    t = i + tau(sim)
    @test event!(sim, :(a += 1), at, t) == t
end

for i ∈ 8:10
    @test event!(sim, :(a += 1), after, i) == 100+i
end

@test event!(sim, :(a += 1), every, 1) == 100

@test length(sim.events) == 11

@test Sim.nextevent(sim).t == 100

incr!(sim)
@test τ(sim) == 100
@test a == 1
@test Sim.nextevent(sim).t == 101

run!(sim, 5)
@test τ(sim) == 105
@test a == 11
@test length(sim.events) == 6
stop = event!(sim, :(stop!(sim)), 108)
run!(sim, 6)
@test a == 16
@test sim.state == Sim.Halted()
@test τ(sim) == stop
resume!(sim)
@test τ(sim) == 111
@test a == 22
@test length(sim.events) == 1

t = 121.0
for i ∈ 1:10
    _t = event!(sim, :(a += 1), 10 + tau(sim))
    @test t == _t
    global t = nextfloat(_t)
end
run!(sim,14)
@test τ(sim) == 125
@test a == 46
@test length(sim.events) == 1
reset!(sim)
@test tau(sim) == 0

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
reset!(sim, hard=false)
@test sim.time == 0

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

sync!(sim, 𝐶)
@test sim.time == 𝐶.time

println("... basic tests with SimFunction, now with 𝐶 ...")
D = Dict(:a=>0, :b=>0, :c=>0)
function f!(D, i)
    D[:a] += 1
    D[:b] = D[:a]^2
    D[:c] = D[:a]^3
end
event!(𝐶, SimFunction(f!, D, 1), every, 1)
run!(𝐶, 20)
@test τ() == 20
@test D[:a] == 21
@test D[:b] == 21^2
@test D[:c] == 21^3
reset!(𝐶)
@test tau() == 0

println("... unit tests ...")
c = Clock(unit = hr)
@test c.unit == hr
c = Clock(1s, t0=1hr, unit=minute)
@test c.time == 60
@test c.unit == minute
@test c.Δt == 1/60
c = Clock(1s)
@test c.unit == s
@test c.Δt == 1
c = Clock(t0=60s)
@test c.unit == s
@test c.time == 60
c = Clock(1s, t0=1hr)
@test c.unit == s
@test c.time == 3600
@test c.Δt ==1
init!(c)
println(c)
@test repr(c) == "Clock: state=Sim.Idle(), time=3600.0, unit=s, events: 0, sampling: 0, sample rate Δt=1.0"

reset!(𝐶)
@test 𝐶.unit == NoUnits
setUnit!(𝐶, s)
@test 𝐶.unit == s
@test setUnit!(𝐶, s) == 0s
c = Clock(1s, t0=1hr)
setUnit!(c, hr)
@test c.unit == hr
@test c.time == 1
@test c.Δt == 1/3600
setUnit!(c, Unitful.m)
@test c.unit == NoUnits

setUnit!(c, s)
run!(𝐶, 1)
sync!(c)
@test c.time == 1
reset!(𝐶)
sync!(c)
c = Clock(t0=1minute)
reset!(𝐶, t0=100s)
sync!(c)
@test c.time == 100
@test c.unit == s

reset!(𝐶, unit=s)
@test 𝐶.unit == s
@test isa(1𝐶.unit, Time)
reset!(𝐶, 1s, t0=1minute)
@test 𝐶.unit == s
@test 𝐶.time == 60
reset!(𝐶, t0=1minute)
@test 𝐶.unit == minute
@test 𝐶.time == 1

myfunc(a, b) = a+b
reset!(𝐶)
@test_warn "clock has no time unit" event!(𝐶, SimFunction(myfunc, 1, 2), 1s)

reset!(𝐶, unit=s)
@test event!(𝐶, SimFunction(myfunc, 4, 5), 1minute, cycle=1minute) == 60
@test event!(𝐶, SimFunction(myfunc, 5, 6), after, 1hr) == 3600
@test sample_time!(𝐶, 30s) == 30
sample!(𝐶, SimFunction(myfunc, 1, 2))
run!(𝐶, 1hr)
@test 𝐶.evcount == 61
