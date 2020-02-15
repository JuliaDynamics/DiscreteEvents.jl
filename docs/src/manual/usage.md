# User guide

## Installation

```@meta
CurrentModule = Simulate
```

`Simulate.jl` runs on Julia versions ≥ v"1.0". Multithreading requires Julia ≥ v"1.3".

```@docs
Simulate
version
```

## Clocks

A clock in `Simulate.jl` is an active object residing in a thread and
registers function calls or expressions as events, schedules them at a given time or under a given condition and executes them at their time or if conditions are met.

- `Clock` and `ActiveClock`s have virtual (simulation) time. A `Clock` can
  control and synchronizes with `ActiveClock`s on other threads. It can be
  started and run for a given time.
- `RTClock`s have real (system) time and operate independently from each other
  and other clocks. They run continuously at given clock ticks and execute
  scheduled events if their time becomes due.

```@docs
Clock
ActiveClock
RTClock
```
Clocks have the following substructures:

```@docs
Schedule
ClockChannel
```

You can set time units and query the current clock time. There is a default clock `𝐶`, which can be used for experimental work. `RTC` can be used to setup and
control real time Clocks.

```@docs
setUnit!
tau
𝐶
RTC
```

You can create a clock with parallel active clocks on all available threads or fork existing clocks to other threads or collapse them if no longer needed. You can get direct access to parallel clocks and diagnose them.

```@docs
PClock
fork!
pclock
collapse!
diagnose
```

!!! note
Directly accessing the `clock` substructure of parallel `ActiveClock`s is possible but not recommended since it breaks parallel operation. The right way is to pass `event!`s to the `ActiveClock`-variable. The communication then happens over the channel to the `ActiveClock` as it should be.

## Events

Julia expressions and functions can be scheduled as events on the clock's timeline and are triggered at a given simulation time or under conditions which may become true during simulation.

Functions and expressions can be scheduled for execution
1. at given clock times and
2. under specified conditions.

```@docs
AbstractEvent
Action
DiscreteEvent
DiscreteCond
Timing
fun
event!
```
Functions and expressions can be given to events on their own or in tuples, even mixed:

```julia
function events()
    event!(:(i += 1), after, 10)  # one expression
    event!(fun(f, 1, 2, 3, diff=pi), every, 1)  # one fun
    event!((:(i += 1), fun(g, j)), [:(tau() ≥ 50), fun(isready, input), :(a ≤ 10)]) # two funs under three conditions
end
```

All given functions or expressions are then called or evaluated at a given simulation time or when during simulation the given conditions become true.

!!! warning
    Evaluating expressions or symbols at global scope is much slower than using
    functions and gives a one time warning. See [Performance](../performance/performance.md). This functionality may be removed entirely in a future version. (Please write an [issue](https://github.com/pbayer/Simulate.jl/issues) if you want to keep it.)

!!! note
    Since conditions often are not met exactly you should prefer inequalities like <, ≤, ≥, > to equality == in order to get sure that a fulfilled condition can be detected, e.g. `:(tau() ≥ 100)` is preferable to `:(tau() == 100)`.

## Continuous sampling

Functions or expressions can register for sampling and are then executed "continuously" at each clock increment Δt.

```@docs
Sample
sample_time!
periodic!
```

## Processes

Julia functions can be registered and run as processes. They follow another (the process-oriented) scheme and can be suspended and reactivated by the scheduler if they wait for something or delay. They must not (but are free to) handle and create events explicitly.

```@docs
Prc
ClockException
process!
interrupt!
stop!(::Prc, ::ClockEvent)
```

### Delay and wait …

Processes do not need to handle their events explicitly, but can call `delay!` or `wait!` or `take!` and `put!` … on their channels. This usually comes in handy. They are then suspended until certain conditions are met or requested resources are available.

```@docs
delay!
wait!
```

### Now

Processes in a simulation want their IO-operations to finish before the clock proceeds. Therefore they must enclose those operations in a `now!` call.

```@docs
now!
```

## Running simulations

If we run the clock, events are triggered, conditions are evaluated, sampling is done and delays are executed … We can also step through a simulation, stop, resume or reset it.

```@docs
reset!
incr!
run!
stop!(::Clock)
resume!
sync!
```
