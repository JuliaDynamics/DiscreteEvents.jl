#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
using DiscreteEvents, .Threads

sleeptime = 0.01
println("... testing real time clock ...")

rtc = createRTClock(0.01, 4711)
stopRTClock(rtc)
rtc.time = 4711.0
thrd = nthreads()
str = "RTClock 4711 on thread $thrd: state=:idle, t=4711.0 s, T=0.01 s, prc:0\n   scheduled ev:0, cev:0, sampl:0\n"
@test repr(rtc) == str

rtc = createRTClock(0.01, 4711)
sleep(1.01)
@test tau(rtc) ≥ 1
t = tau(rtc)
resetClock!(rtc)
sleep(sleeptime)
@test tau(rtc) < t

put!(rtc.cmd, DiscreteEvents.Clear())
sleep(sleeptime)
put!(rtc.cmd, DiscreteEvents.Diag())
err = take!(rtc.back).x
@test err[1] isa ErrorException

a = [0]
b = [0]
incr!(x) = x[1] += 1
event!(rtc, fun(incr!, a), every, 0.1)
periodic!(rtc, fun(incr!, b))
sleep(1)
@test a[1] ≥ 10
@test b[1] ≥ 100

old = DiscreteEvents._handle_exceptions[end]
DiscreteEvents._handle_exceptions[end] = false
sleep(1)
@test a[1] ≥ 20
@test b[1] ≥ 200
DiscreteEvents._handle_exceptions[end] = old

stopRTClock(rtc)
t = tau(rtc)
sleep(0.1)
@test t == tau(rtc)
