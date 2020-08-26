#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#
using DiscreteEvents, Distributions, Test

println("... timed events ...")

a = [0.0]
b = [0.0]
c = [0.0]
d = [0.0]
incr!(x) = x[1] += 1

clk = Clock()

foreach(i -> event!(clk, fun(incr!, a), i), 1:5) # 1st case
@test length(clk.sc.events) == 5
foreach(i -> event!(clk, fun(incr!, a), Normal(i, 0)), 6:10) # 2nd case
@test length(clk.sc.events) == 10
event!(clk, fun(incr!, b), 1, 1) # 3rd case
@test length(clk.sc.events) == 11
event!(clk, fun(incr!, c), 1, Normal(1, 0)) # 4th case
@test length(clk.sc.events) == 12
event!(clk, fun(incr!, d), Normal(1, 0), Normal(1, 0)) # 5th case
@test length(clk.sc.events) == 13

run!(clk, 10)
@test a[1] == 10
@test b[1] == 10
@test c[1] == 10
@test d[1] == 10

# test events with Timing
resetClock!(clk)
a[1] = b[1] = c[1] = d[1] = 0
foreach(i -> event!(clk, fun(incr!, a), at, i), 1:5)
foreach(i -> event!(clk, fun(incr!, a), at, Normal(i,0)), 6:10)
foreach(i -> event!(clk, fun(incr!, b), after, i), 1:5)
foreach(i -> event!(clk, fun(incr!, b), after, Normal(i,0)), 6:10)
event!(clk, fun(incr!, c), every, 1)
event!(clk, fun(incr!, d), every, Normal(1,0))
@test length(clk.sc.events) == 22

run!(clk, 10)
@test a[1] == 10
@test b[1] == 10
@test c[1] == 10
@test d[1] == 10

# the same with default clock
resetClock!(𝐶)
a[1] = b[1] = c[1] = d[1] = 0
foreach(i -> event!(fun(incr!, a), i), 1:5) # 1st case
foreach(i -> event!(fun(incr!, a), Normal(i, 0)), 6:10) # 2nd case
event!(fun(incr!, b), 1, 1) # 3rd case
event!(fun(incr!, c), 1, Normal(1, 0)) # 4th case
event!(fun(incr!, d), Normal(1, 0), Normal(1, 0)) # 5th case
@test length(𝐶.sc.events) == 13

run!(𝐶, 10)
@test a[1] == 10
@test b[1] == 10
@test c[1] == 10
@test d[1] == 10

# test events with Timing and default clock
resetClock!(𝐶)
a[1] = b[1] = c[1] = d[1] = 0
foreach(i -> event!(fun(incr!, a), at, i), 1:5)
foreach(i -> event!(fun(incr!, a), at, Normal(i,0)), 6:10)
foreach(i -> event!(fun(incr!, b), after, i), 1:5)
foreach(i -> event!(fun(incr!, b), after, Normal(i,0)), 6:10)
event!(fun(incr!, c), every, 1)
event!(fun(incr!, d), every, Normal(1,0))
@test length(𝐶.sc.events) == 22

run!(𝐶, 10)
@test a[1] == 10
@test b[1] == 10
@test c[1] == 10
@test d[1] == 10

println("... conditional events ...")
is(x, y) = x[1] == y
tim(x, clk) = x[1] = clk.time
resetClock!(clk)
a[1] = b[1] = c[1] = d[1] = 0
event!(clk, fun(incr!, a), every, 1)
event!(clk, fun(tim, b, clk), (fun(is, d, 3), fun(x->x[1]≥5, a)))

# mock clk.state = Busy
state = clk.state
clk.state = DiscreteEvents.Busy()
event!(clk, fun(incr!, c), (fun(is, a, 0), fun(is, b, 0))) # execute immediately
@test c[1] == 1
clk.state = state

event!(clk, fun(event!, clk, fun(tim, d, clk), fun(is, c, 1)), 3) # execute immediately at 3

@test length(clk.sc.cevents) == 1  # only the 1st cevent is scheduled
@test DiscreteEvents._evaluate(clk.sc.cevents[1].cond) == (false, false)
@test DiscreteEvents._nextevent(clk).t == 1


run!(clk, 6)
@test tau(clk) == 6
@test a[1] == 6
@test b[1] ≈ 5 + clk.Δt            # 1st cevent must have fired 
@test d[1] == 3
@test length(clk.sc.cevents) == 0  # and has disappeared
@test length(clk.sc.events) == 1   # but repeat event is still scheduled

println("... sampling ...")
clk = Clock(1)  # clock with sample rate 1
periodic!(clk, fun(incr!, a), 0)
@test clk.Δt == 0.01
clk.time = 10
clk.evcount = 1000
periodic!(clk, fun(incr!, a), 0)
@test clk.Δt == 0.0001

clk = Clock(1)  # clock with sample rate 1
@test clk.time == 0
@test clk.tn == 1
@test clk.Δt == 1

b[1] = 0
periodic!(clk, fun(incr!, b))
@test length(clk.sc.samples) == 1
run!(clk, 10)
@test clk.time == 10
@test b[1] == 10
sample_time!(clk, 0.5)
run!(clk, 10)
@test clk.time == 20
@test b[1] == 30

println("... everything events and sampling ...")
a[1] = b[1] = 0
clk = Clock(0.5)
event!(clk, fun(incr!, a), every, 0.5)
event!(clk, fun(incr!, a), every, TruncatedNormal(1, 0.3, 0.5, 2))
event!(clk, fun(event!, clk, fun(incr!, a), fun((c, x)->c.time ≥ x, clk, clk.time+2rand())), every, Exponential(5))
periodic!(clk, fun(incr!, b))
run!(clk, 10000)
@test a[1] == clk.evcount
@test b[1] == 20000

println("... everything events and sampling with 𝐶 ...")
a[1] = b[1] = 0
resetClock!(𝐶)
sample_time!(0.5)
event!(fun(incr!, a), every, 0.5)
event!(fun(incr!, a), every, TruncatedNormal(1, 0.3, 0.5, 2))
event!(fun(event!, fun(incr!, a), fun(x->tau() ≥ x, tau()+2rand())), every, Exponential(5))
periodic!(fun(incr!, b))
run!(clk, 10000)
@test a[1] == clk.evcount
@test b[1] == 20000
