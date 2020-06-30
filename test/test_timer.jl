#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

println("... testing real time clock ...")

rtc = createRTClock(0.01, 4711)
sleep(1)
@test tau(rtc) ≥ 1

a = 0
f() = global a += 1
event!(rtc, f, every, 0.1)
sleep(1)
@test a ≥ 10

stopRTClock(rtc)
t = tau(rtc)
sleep(0.1)
@test t == tau(rtc)
