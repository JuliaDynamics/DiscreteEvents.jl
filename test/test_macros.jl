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

clk = Clock()

@test repr(@macroexpand @event h(clk, a, b) at a) == ":(event!(clk, fun(h, clk, a, b), at, a))"
@test repr(@macroexpand @event h(clk, a, b) every a 10) == ":(event!(clk, fun(h, clk, a, b), every, a, n = 10))"
@test repr(@macroexpand @event h(clk, a, b) g(x, y)) == ":(event!(clk, fun(h, clk, a, b), fun(g, x, y)))"
@test repr(@macroexpand @event h(clk, a, b) a==1) == ":(event!(clk, fun(h, clk, a, b), fun(==, a, 1)))"

@test repr(@macroexpand @process h(clk, a, b)) == ":(process!(clk, Prc(h, a, b)))"
@test repr(@macroexpand @delay clk a) == ":(delay!(clk, a))"

@test repr(@macroexpand @wait clk g(a,b)) == ":(wait!(clk, fun(g, a, b)))"

@test repr(@macroexpand @run! clk a) == ":(run!(clk, a))"


