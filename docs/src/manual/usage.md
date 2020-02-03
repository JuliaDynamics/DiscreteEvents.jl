# User guide

## Installation

```@meta
CurrentModule = Simulate
```

`Simulate.jl` runs on Julia versions ≥ v"1.0".

```@docs
Simulate
version
```

## The clock

A clock in `Simulate.jl` is an active object residing in a thread and continuously
registering function calls or expressions as events, scheduling them for execution
or evaluation at a given time or under a given condition and executing them at
their time or if conditions are met.

A clock can be created. It is operated as a state machine. It can control
active clocks on other threads.

```@docs
Clock
PClock
ActiveClock
pclock
```
Clocks have the following substructures:

```@docs
Schedule
AC
```

There is a default central clock 𝐶. You can set time units and query the current simulation time.

```@docs
𝐶
setUnit!
tau(::Clock)
```

You can fork single clocks to multiple threads or collapse them if no longer needed and diagnose parallel clocks.

```@docs
fork!
collapse!
diag
```

## Events

Julia expressions and functions can be scheduled as events on the clock's timeline and are triggered at a given simulation time or under conditions which may become true during simulation.

Functions and expressions can be scheduled for execution
1. at given clock times and
2. under specified conditions.

```@docs
DiscreteEvent
DiscreteCond
Timing
Fun
Action
event!
```
Functions and expressions can be given to events on their own or in tuples, even mixed:

```julia
function events()
    event!(:(i += 1), after, 10)  # one expression
    event!(Fun(f, 1, 2, 3, diff=pi), every, 1)  # one Fun
    event!((:(i += 1), Fun(g, j)), [:(tau() ≥ 50), Fun(isready, input), :(a ≤ 10)]) # two Fun under three conditions
end
```

All given functions or expressions are then called or evaluated at a given simulation time or when during simulation the given conditions become true.

!!! warning
    Evaluating expressions or symbols at global scope is much slower than using
    `Fun`s and gives a one time warning. See [Performance](../performance/performance.md).
    This functionality may be removed entirely in a future version. (Please write
    an [issue](https://github.com/pbayer/Simulate.jl/issues) if you want to keep it.)

!!! note
    Since conditions often are not met exactly you should prefer inequalities like <, ≤, ≥, > to equality == in order to get sure that a fulfilled condition can be detected, e.g. `:(tau() ≥ 100)` is preferable to `:(tau() == 100)`.

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

## Continuous sampling

Functions or expressions can register for sampling and are then executed "continuously" at each clock increment Δt.

```@docs
Sample
sample_time!
periodic!
```

## Running simulations

If we run the clock, events are triggered, conditions are evaluated, sampling is done and delays are executed … Thus we run a simulation. We can also step through a simulation or stop and resume a clock, reset ist and so on.

```@docs
reset!
incr!
run!
stop!(::Clock)
resume!
sync!
```
