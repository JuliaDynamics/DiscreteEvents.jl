# Clocks

```@meta
CurrentModule = DiscreteEvents
```

Clocks schedule and execute *actions*, computations that happen as *events* at specified times (or under specified conditions).

## Virtual Clocks

A `Clock` is not bound to physical time and executes an event sequence as fast as possible by jumping from event to event.

```@docs
Clock
Clock(::T) where T<:Number
```

You can create clocks easily:

```@repl clocks
using DiscreteEvents, Unitful, .Threads
import Unitful: s, minute, hr
c = Clock()                  # create a unitless clock (standard)
c1 = Clock(1s, unit=minute)  # create a clock with unit [minute]
c2 = Clock(1s)               # create a clock with implicit unit [s]
c3 = Clock(t0=60s)           # another clock with implicit unit [s]
c4 = Clock(1s, t0=1hr)       # here Δt's unit [s] takes precedence
```

There is a default clock `𝐶` for experimental work:

```@docs
𝐶
```

You can query the current clock time:

```@docs
tau
```

## Real Time Clocks (Experimental)

Real time clocks are a new feature in v0.3 and thus cannot yet be considered as stable. Please try and report problems.

`RTClock`s schedule and execute actions on a real (system) time line.

```@docs
RTClock
createRTClock
stopRTClock
```

You can work with real time clocks easily:

```@repl clocks
rtc = createRTClock(0.01, 99)     # create a real time clock
sleep(1)
tau(rtc)                          # query its time after a sleep
a = [1]                           # create a mutable variable
f(x) = x[1] += 1                  # an incrementing function 
event!(rtc, fun(f, a), every, 1)  # increment now and then every second 
sleep(3)                          # sleep 3 seconds
a[1]                              # query a
stopRTClock(rtc)                  # stop the clock
```

## Clock Operation

Virtual clocks can be run, stopped or stepped through and thereby used to simulate chains of events.

```@docs
run!
@run!
incr!
resetClock!
stop!
resume!
sync!
```

## Time Units

You can set time units of a virtual clock:

```@docs
setUnit!
```

!!! note

    This is not yet implemented for parallel clocks!
