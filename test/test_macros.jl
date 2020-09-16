#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#
using DiscreteEvents

a = 1
b = 1
f(x, y) = x+y
g(x, y) = x == y
h(clk, x, y) = clk.time + x + y
incra(clk) = global a += 1

clk = Clock()

# 1st @event macro: timed events
@test repr(@macroexpand @event h(clk, a, b) at a) == ":(event!(clk, fun(h, clk, a, b), at, a))"
VERSION > v"1.5" && @test repr(@macroexpand @event h(clk, a, b) every a 10) == ":(event!(clk, fun(h, clk, a, b), every, a, n = 10))"

# 2nd @event macro: conditional events
@test repr(@macroexpand @event h(clk, a, b) g(x, y)) == ":(event!(clk, fun(h, clk, a, b), fun(g, x, y)))"
@test repr(@macroexpand @event h(clk, a, b) a==1) == ":(event!(clk, fun(h, clk, a, b), fun(==, a, 1)))"
@test repr(@macroexpand @event h(clk, a, b) a) == ":(event!(clk, fun(h, clk, a, b), a))"

@event incra(clk) every 1
@event stop!(clk) ()->a ≥ 2 && tau(clk) ≥ 5  # @event with an anonymous function condition
@run! clk 10
@test clk.time ≈ 5.01
@test clk.evcount == 5

@test repr(@macroexpand @periodic h(clk, a, b)) == ":(periodic!(clk, fun(h, clk, a, b)))"
@test repr(@macroexpand @periodic h(clk, a, b) 1) == ":(periodic!(clk, fun(h, clk, a, b), 1))"

@test repr(@macroexpand @process h(clk, a, b)) == ":(process!(clk, Prc(h, a, b)))"
@test repr(@macroexpand @process h(clk, a, b) 10) == ":(process!(clk, Prc(h, a, b), 10))"

@test repr(@macroexpand @delay clk a) == ":(delay!(clk, a))"
@test repr(@macroexpand @delay clk until 10) == ":(delay!(clk, until, 10))"

@test repr(@macroexpand @wait clk g(a,b)) == ":(wait!(clk, fun(g, a, b)))"

@test repr(@macroexpand @run! clk a) == ":(run!(clk, a))"


