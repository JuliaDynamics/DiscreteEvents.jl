#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#
using DiscreteEvents

println("... basic tests: printing  ...")
resetClock!(𝐶)
DiscreteEvents.prettyClock(true)
str = "Clock 1: state=:idle, t=0.0, Δt=0.01, prc:0\n  scheduled ev:0, cev:0, sampl:0\n"
@test repr(𝐶) == str
DiscreteEvents.prettyClock(false)
str = "Clock{Array{DiscreteEvents.ClockChannel,1}}(1, DiscreteEvents.ClockChannel[], DiscreteEvents.Idle(), 0.0, , 0.01, DiscreteEvents.Schedule(DataStructures.PriorityQueue{DiscreteEvents.DiscreteEvent,Float64,Base.Order.ForwardOrdering}(), DiscreteEvents.DiscreteCond[], DiscreteEvents.Sample[]), Dict{Any,Prc}(), Channel[], 0.0, 0.0, 0.0, 0, 0)"
@test repr(𝐶) == str
DiscreteEvents.prettyClock(true)
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

@test DiscreteEvents._evaluate(fun(e)) == 123
@test DiscreteEvents._evaluate(fun(f, 1)) == 4
@test DiscreteEvents._evaluate(fun(h, 1, 2, c=3, d=4)) == 10

a = 11; b = 12; c = 13; d = 14;
sf1 = fun(h, a, b, c=c, d=d)
sf2 = fun(h, :a, :b, c=:c, d=:d)
sf3 = fun(h, a, b, c=c, d=d)
sf4 = fun(h, :a, :b, c=:c, d=:d)
sf5 = fun(i, a=a, b=b)
sf6 = fun(event!, fun(f, a), 1, cid=2, spawn=true)
@test sf1() == 50
@test sf2() == 50
@test sf3() == 50
@test sf4() == 50
@test sf5() == 23
sf6()
ev = DiscreteEvents._nextevent(𝐶)
@test ev.ex() == 14
a = 21; b = 22; c = 23; d = 24;
@test sf1() == 50
@test sf2() == 90
@test fun(h, :a, 2, c=:c, d=4)() == 50
@test fun(j, :unknown)()
@test fun(<=, fun(tau), 1)()

@test fun(i, a=10, b=20)() == 30

# one expression
ev = DiscreteEvents.DiscreteEvent(:(1+1), 10.0, nothing)
@test DiscreteEvents._evaluate(ev.ex) == 2
@test ev.t == 10

# two expressions
ev = DiscreteEvents.DiscreteEvent((:(1+1), :(1+2)), 15.0, nothing)
@test DiscreteEvents._evaluate(ev.ex) == (2, 3)
@test ev.t == 15

# one fun
ev = DiscreteEvents.DiscreteEvent(fun(f, 1), 10.0, nothing)
@test DiscreteEvents._evaluate(ev.ex) == 4

# two funs
ev = DiscreteEvents.DiscreteEvent((fun(f, 1), fun(g, 1)), 10.0, nothing)
@test DiscreteEvents._evaluate(ev.ex) == (4, 5)

# expressions and funs mixed in a tuple
ev = DiscreteEvents.DiscreteEvent((:(1+1), fun(g,2), :(1+2), fun(f, 1)), 10.0, nothing)
@test sum([DiscreteEvents._evaluate(ex) for ex in ev.ex if ex isa Function]) == 10
@test sum([eval(ex) for ex in ev.ex if isa(ex, Expr)]) == 5
@test DiscreteEvents._evaluate(ev.ex) == (2, 6, 3, 4)

@test DiscreteEvents._scale(0) == 1
@test DiscreteEvents._scale(pi*1e7) == 1e7

clk = Clock()  # set up clock without sampling
@test_warn "undefined transition" DiscreteEvents.step!(clk, clk.state, DiscreteEvents.Resume())
DiscreteEvents.init!(clk)
@test clk.state == DiscreteEvents.Idle()
@test tau(clk) == 0
clk = Clock(t0=100)
@test tau(clk) == 100
# @test_warn "nothing to _evaluate" incr!(clk)
