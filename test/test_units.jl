#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#
using DiscreteEvents, Unitful
import Unitful: Time, ms, s, minute, hr

println("... unit tests ...")
clk = Clock(unit = hr)
@test clk.unit == hr
clk = Clock(1s, t0=1hr, unit=minute)
@test clk.time == 60
@test clk.unit == minute
@test clk.Δt == 1/60
clk = Clock(1s)
@test clk.unit == s
@test clk.Δt == 1
clk = Clock(t0=60s)
@test clk.unit == s
@test clk.time == 60
clk = Clock(1s, t0=1hr)
@test clk.unit == s
@test clk.time == 3600
@test clk.Δt ==1
@test repr(clk) == "Clock 1: state=:idle, t=3600.0s, Δt=1.0s, prc:0\n  scheduled ev:0, cev:0, sampl:0\n"

resetClock!(𝐶)
@test 𝐶.unit == NoUnits
setUnit!(𝐶, s)
@test 𝐶.unit == s
@test setUnit!(𝐶, s) == 0s
clk = Clock(1s, t0=1hr)
setUnit!(clk, hr)
@test clk.unit == hr
@test clk.time == 1
@test clk.Δt == 1/3600
setUnit!(clk, Unitful.m)
@test clk.unit == NoUnits

setUnit!(clk, s)
resetClock!(𝐶, t0=1)
sync!(clk)
@test clk.time == 1
resetClock!(𝐶)
sync!(clk)
clk = Clock(t0=1minute)
resetClock!(𝐶, t0=100s)
sync!(clk)
@test clk.time == 100
@test clk.unit == s

resetClock!(𝐶, unit=s)
@test 𝐶.unit == s
@test isa(1𝐶.unit, Time)
resetClock!(𝐶, 1s, t0=1minute)
@test 𝐶.unit == s
@test 𝐶.time == 60
resetClock!(𝐶, t0=1minute)
@test 𝐶.unit == minute
@test 𝐶.time == 1

myfunc(a, b) = a+b
resetClock!(𝐶)
@test_warn "clock has no time unit" event!(𝐶, fun(myfunc, 1, 2), 1s)

resetClock!(𝐶, unit=s)
event!(𝐶, fun(myfunc, 4, 5), 1minute, 1minute)
event!(𝐶, fun(myfunc, 5, 6), after, 1hr)
@test sample_time!(𝐶, 30s) == 30
periodic!(𝐶, fun(myfunc, 1, 2))
run!(𝐶, 1hr)
@test 𝐶.evcount == 61
