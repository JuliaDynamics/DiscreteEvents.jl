# Clocks

```@meta
CurrentModule = DiscreteEvents
```

Clocks schedule and execute *actions*, computations that happen as *events* at specified times (or under specified conditions).

## Virtual Clocks

A `Clock` is not bound to physical time and executes an event sequence as fast as possible.

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

## Parallel Clocks (Experimental)

Working with parallel clocks over multiple threads is a new feature in v0.3 and cannot yet considered to be stable. Please develop your applications first single-threaded before going parallel. Please report any failures.

Parallel clocks are virtual clocks with local clocks on parallel threads to support multi-threaded simulations.

A parallel clock structure consists of a master (global) clock on thread 1 and [`ActiveClock`](@ref)s on all available threads > 1. An active clock is a task running a thread local clock. The thread local clock can schedule and execute events locally.

The master clock communicates with its parallel active clocks via message channels. It synchronizes time with the local clocks. Tasks (processes and actors) can get access to their thread local clock from it and then work only with the local clock.

```@docs
PClock
pclock
```

Parallel clocks can be identified by their thread number: the master clock works on thread 1, local clocks on parallel threads ≥ 2. They can be setup and accessed easily:

```@repl clocks
@show x=nthreads()-1;
clk = PClock()       # now the clock has (+x) active parallel clocks
ac2 = pclock(clk, 2) # access the active clock on thread 2
ac2.clock            # the thread local clock
ac2.clock.ac[]       # local clocks can access their active clock
```

Tasks on parallel threads have access to the thread local clock by `pclock(clk)`. Then they can schedule events, `delay!` or `wait!` on it as usual. The thread local clock is passed to a `process!` automatically if you set it up on a parallel thread.

You can fork explicitly existing clocks to other threads or collapse them if no longer needed. You can get direct access to parallel active clocks and diagnose them.

```@docs
fork!
collapse!
diagnose
```

## Real Time Clocks (Experimental)

`RTClock`s schedule and execute actions on a real (system) time line.

!!! warning "Real time clocks are experimental!"

    Real time clocks are a new feature in v0.3 and thus cannot yet be considered as stable. Please try and report problems.

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
