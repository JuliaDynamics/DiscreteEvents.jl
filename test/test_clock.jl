#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#
using DiscreteEvents, Unitful
import Unitful: Time, ms, s, minute, hr

resetClock!(𝐶)

clk = Clock(t0=60, unit=s)
@test tau(clk) == 60s
@test clk.time == 60
@test clk.Δt == 0.01
@test clk.unit == s

resetClock!(clk)
@test tau(clk) == 0
@test clk.Δt == 0.01
@test clk.unit == NoUnits

clk = Clock(t0=60, unit=s)
@test_warn "deleted time unit" sync!(clk)
@test tau(clk) == 0
@test clk.Δt == 0.01
@test clk.unit == NoUnits

a = [0.0]
incr!(x) = x[1] += 1
event!(clk, fun(incr!, a), every, 1)
DiscreteEvents.incr!(clk)
@test a[1] == 1
@test clk.time == 1
event!(clk, fun(DiscreteEvents.stop!, clk), 5.1)
run!(clk, 9)
@test clk.state == DiscreteEvents.Halted()
@test a[1] == 5
@test clk.time == 5.1
@test clk.end_time == 10
resume!(clk)
@test clk.time == 10
@test a[1] == 10


@test_warn  "undefined transition" DiscreteEvents.init!(clk)
clk.state = DiscreteEvents.Undefined()
DiscreteEvents.init!(clk)
@test clk.state == DiscreteEvents.Idle()
