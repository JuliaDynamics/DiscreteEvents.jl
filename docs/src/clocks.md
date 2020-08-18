# Clocks

```@meta
CurrentModule = DiscreteEvents
```

Clocks schedule and execute *actions*, computations that happen as *events* at specified times (or under specified conditions).

## Virtual clocks

`Clock`s have virtual time and precede as fast as possible. A virtual (single-threaded) clock has always an identification number 1.

```@docs
Clock
Clock(::T) where T<:Number
```

You can create clocks easily:

```@repl usage
using DiscreteEvents, Unitful, .Threads
import Unitful: s, minute, hr
c = Clock()                  # create a unitless clock (standard)
c1 = Clock(1s, unit=minute)  # create a clock with unit [minute]
c2 = Clock(1s)               # create a clock with implicit unit [s]
c3 = Clock(t0=60s)           # another clock with implicit unit [s]
c4 = Clock(1s, t0=1hr)       # here Δt's unit [s] takes precedence
```

There is a default clock `𝐶`, which can be used for experimental work.

```@docs
𝐶
```

You can query the current clock time and set time units.

```@docs
tau
setUnit!
```

## Parallel clocks

Parallel clocks control [`ActiveClock`](@ref)s on parallel threads to support parallel simulations.

!!! warning "Parallel clocks are experimental!"

    Working with parallel clocks over multiple threads is a new feature in v0.3 and cannot yet considered to be stable. Please develop your applications first single-threaded before going parallel. Please report any failures.

A parallel clock structure consists of a master (global) clock on thread 1 and [`ActiveClock`](@ref)s on all available threads > 1. An active clock is a task running a thread local clock. The thread local clock provides the same functionality for applications as does master.

The master clock communicates with its parallel active clocks via message channels. It synchronizes time with the local clocks. Tasks (processes and actors) can get access to their thread local clock from it and then need to work only with the local clock.

```@docs
PClock
pclock
```

Parallel clocks can be identified by their thread number: the master clock works on thread 1, local clocks on parallel threads ≥ 2. They can be setup and accessed easily:

```@repl usage
@show x=nthreads()-1;
clk = PClock()       # now the clock has (+x) active parallel clocks
ac2 = pclock(clk, 2) # access the active clock on thread 2
ac2.clock            # access their thread local clock
ac2.clock.ac[]       # local clocks can access their active clock
```

Tasks on parallel threads can get access to the thread local clock by `pclock(clk)`. Then they can schedule events, `delay!` or `wait!` on it as usual.

You can fork explicitly existing clocks to other threads or collapse them if no longer needed. You can get direct access to parallel active clocks and diagnose them.

```@docs
fork!
collapse!
diagnose
```

## Real time clocks

`RTClock`s schedule and execute actions on a real (system) time line. They have user defined id numbers.

!!! warning "Real time clocks are experimental!"

    Real time clocks are a new feature in v0.3 and thus cannot yet be considered as stable. Please try and report problems.

```@docs
RTClock
createRTClock
stopRTClock
```

example

## Clock operation

Virtual clocks can be run, stopped or stepped through and thereby used to simulate chains of events.

```@docs
run!
incr!
resetClock!
stop!
resume!
sync!
```
