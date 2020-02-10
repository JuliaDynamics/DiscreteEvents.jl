#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

println("... basic tests: printing  ...")
str = "Clock thread 1 (+ 0 ac): state=Simulate.Idle(), t=0.0 , Δt=0.0 , prc:0\n  scheduled ev:0, cev:0, sampl:0\n"
reset!(𝐶)
@test repr(𝐶) == str
Simulate._show_default[1] = true
str = "Clock(0, Simulate.Idle(), 0.0, , 0.0, Simulate.ClockChannel[], Simulate.Schedule(DataStructures.PriorityQueue{Simulate.DiscreteEvent,Float64,Base.Order.ForwardOrdering}(), Simulate.DiscreteCond[], Simulate.Sample[]), Dict{Any,Prc}(), 0.0, 0.0, 0.0, 0, 0)"
@test repr(𝐶) == str
Simulate._show_default[1] = false
@test tau() == 0

println("... basic tests: only events  ...")
ex1 = :(1+1)
ex2 = :(1+2)
e() = 123
f(a) = a+3
g(a) = a+4
h(a, b; c = 1, d = 2) = a + b + c + d
i(; a = 1, b = 2) = a + b
j(x) = x == :unknown

@test Simulate.evExec(fun(e)) == 123
@test Simulate.evExec(fun(f, 1)) == 4
@test Simulate.evExec(fun(h, 1, 2, c=3, d=4)) == 10

a = 11; b = 12; c = 13; d = 14;
sf1 = fun(h, a, b, c=c, d=d)
sf2 = fun(h, :a, :b, c=:c, d=:d)
sf3 = fun(h, a, b, c=c, d=d)
sf4 = fun(h, :a, :b, c=:c, d=:d)
@test Simulate.evExec(sf1) == 50
@test Simulate.evExec(sf2) == 50
@test Simulate.evExec(sf3) == 50
@test Simulate.evExec(sf4) == 50
a = 21; b = 22; c = 23; d = 24;
@test Simulate.evExec(sf1) == 50
@test Simulate.evExec(sf2) == 90
@test Simulate.evExec(fun(h, :a, 2, c=:c, d=4)) == 50
@test Simulate.evExec(fun(j, :unknown))
@test Simulate.evExec(fun(<=, fun(tau), 1))

@test Simulate.evExec((fun(i, a=10, b=20))) == 30

# one expression
ev = Simulate.DiscreteEvent(:(1+1), Main, 10.0, 0.0)
@test Simulate.evExec(ev.ex) == 2
@test ev.t == 10

# two expressions
ev = Simulate.DiscreteEvent((:(1+1), :(1+2)), Main, 15.0, 0.0)
@test Simulate.evExec(ev.ex) == (2, 3)
@test ev.t == 15

# one fun
ev = Simulate.DiscreteEvent(fun(f, 1), Main, 10.0, 0.0)
@test Simulate.evExec(ev.ex) == 4

# two funs
ev = Simulate.DiscreteEvent((fun(f, 1), fun(g, 1)), Main, 10.0, 0.0)
@test Simulate.evExec(ev.ex) == (4, 5)

# expressions and funs mixed in a tuple
ev = Simulate.DiscreteEvent((:(1+1), fun(g,2), :(1+2), fun(f, 1)), Main, 10.0, 0.0)
@test sum([Simulate.evExec(ex) for ex in ev.ex if ex isa Function]) == 10
@test sum([eval(ex) for ex in ev.ex if isa(ex, Expr)]) == 5
@test Simulate.evExec(ev.ex) == (2, 6, 3, 4)

@test Simulate.scale(0) == 1
@test Simulate.scale(pi*1e7) == 1e7

sim = Clock()  # set up clock without sampling
@test_warn "undefined transition" Simulate.step!(sim, sim.state, Simulate.Resume())
Simulate.init!(sim)
@test sim.state == Simulate.Idle()
@test tau(sim) == 0
sim = Clock(t0=100)
@test tau(sim) == 100
# @test_warn "nothing to evaluate" incr!(sim)

a = 0
b = 0

for i ∈ 1:4
    t = i + tau(sim)
    event!(sim, :(a += 1), t)
end

for i ∈ 5:7
    t = i + tau(sim)
    event!(sim, :(a += 1), at, t)
end

for i ∈ 8:10
    event!(sim, :(a += 1), after, i)
end

event!(sim, :(a += 1), every, 1)

# conditional events
@test sim.Δt == 0
event!(sim, :(a +=1), (:(tau(sim)>110), :(a>20)))
event!(sim, :(b +=1), (:(a==0), :(b==0)))              # execute immediately
event!(sim, fun(event!, sim, :(b +=10), :(b==1)), 103) # execute immediately at 103
@test length(sim.sc.cevents) == 2
@test Simulate.evExec(sim.sc.cevents[1].cond) == (false, false)
@test sim.Δt == 0.01

@test length(sim.sc.events) == 12
@test Simulate.nextevent(sim).t == 100

incr!(sim)
@test tau(sim) == 100
@test a == 1
@test b == 1
@test Simulate.nextevent(sim).t == 101

run!(sim, 5)
@test tau(sim) == 105
@test a == 11
@test b == 11
@test length(sim.sc.events) == 6
event!(sim, :(stop!(sim)), 108)
run!(sim, 6)
@test a == 16
@test sim.state == Simulate.Halted()
@test length(sim.sc.cevents) == 1
resume!(sim)
@test tau(sim) == 111
@test length(sim.sc.cevents) == 0
@test a == 23
@test length(sim.sc.events) == 1

t = 121.0
for i ∈ 1:10
    event!(sim, :(a += 1), 10 + tau(sim))
end
run!(sim,14)
@test tau(sim) == 125
@test a == 47
@test length(sim.sc.events) == 1
reset!(sim)
@test tau(sim) == 0

println("... basic tests: sampling ...")
sim = Clock(1)  # clock with sample rate 1
@test sim.time == 0
@test sim.tn == 1
@test sim.Δt == 1

b = 0
periodic!(sim, :(b += 1))
@test length(sim.sc.samples) == 1
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
periodic!(sim, :(bar()))
run!(sim, 10000)
@test a == sim.evcount
@test b == 20000

sync!(sim, 𝐶)
@test sim.time == 𝐶.time

println("... basic tests with fun, now with 𝐶 ...")
D = Dict(:a=>0, :b=>0, :c=>0)
function f!(D, i)
    D[:a] += 1
    D[:b] = D[:a]^2
    D[:c] = D[:a]^3
end
a = 0
b = 0
event!(fun(() -> global a += 1), 1)
event!(fun(() -> global b += 1), 9.5, cycle=1)
event!(𝐶, fun(f!, D, 1), every, 1)
run!(𝐶, 20)
@test tau() == 20
@test D[:a] == 21
@test D[:b] == 21^2
@test D[:c] == 21^3
@test a == 1
@test b == 11

reset!(𝐶)
sample_time!(1)
@test 𝐶.Δt == 1

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
Simulate.init!(c)
println(c)
# @test repr(c) == "Clock: state=Simulate.Idle(), time=3600.0, unit=s, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=1.0"

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
@test_warn "clock has no time unit" event!(𝐶, fun(myfunc, 1, 2), 1s)

reset!(𝐶, unit=s)
event!(𝐶, fun(myfunc, 4, 5), 1minute, cycle=1minute)
event!(𝐶, fun(myfunc, 5, 6), after, 1hr)
@test sample_time!(𝐶, 30s) == 30
periodic!(𝐶, fun(myfunc, 1, 2))
run!(𝐶, 1hr)
@test 𝐶.evcount == 61
