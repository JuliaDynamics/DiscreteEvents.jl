# User guide

## Installation

```@meta
CurrentModule = DiscreteEvents
```

```@docs
DiscreteEvents
version
```

## Clocks

Clock schedule and execute Julia functions or expressions as events at given times or
under given conditions.

- `Clock`s have virtual time and precede as fast as possible when they simulate chains of
  events. For parallel simulations they can control [`ActiveClock`](@ref)s on parallel
  threads.
- `RTClock`s schedule and execute events on a real (system) time line.

Clocks have an ident number:
- a master `Clock` on thread has id = 0,
- worker [`ActiveClock`](@ref)s on parallel threads have id ≥ 1,
- real time `RTClock`s have id ≤ -1.

```@docs
Clock
RTClock
```

You can set time units and query the current clock time.

```@docs
setUnit!
tau
```

There is a default clock `𝐶`, which can be used for experimental work.

```@docs
𝐶
```

`RTC` can be used to setup and control real time Clocks.

```@docs
RTC
```

You can create a clock with parallel active clocks on all available threads or fork existing clocks to other threads or collapse them if no longer needed. You can get direct access to parallel [`ActiveClock`](@ref)s and diagnose them.

```@docs
PClock
fork!
pclock
collapse!
diagnose
```

## Events

Julia functions and expressions can be scheduled for execution
1. at given clock times and
2. under specified conditions.

```@docs
Action
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

Scheduled events are called or evaluated during simulation at a given time or when the
given conditions become true.

!!! note
    For conditions you should prefer inequalities like <, ≤, ≥, > to equality == in order to get sure that a fulfilled condition can be detected, e.g. `tau() ≥ 100` is preferable to `tau() == 100`.

## Continuous sampling

Functions or expressions can register for sampling and are then executed "continuously" at each clock increment Δt.

```@docs
sample_time!
periodic!
```

## Processes

Julia functions can be registered and run as processes (asynchronous tasks).

```@docs
Prc
process!
interrupt!
```

### Delay and wait …

Processes do not need to handle their events explicitly, but can call `delay!` or `wait!` or `take!` and `put!` … on their channels. They are then suspended until a given time or until certain conditions are met or requested resources are available.

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

If we run the clock, events are triggered, conditions are evaluated, sampling is done and delays are simulated … We can also step through a simulation, stop, resume or reset it.

```@docs
resetClock!
incr!
run!
onthread
stop!
resume!
sync!
```

## Resources

Shared resources with limited capacity are often needed in simulations.

1. One approach to model them is to use Julia [`Channel`](https://docs.julialang.org/en/v1/base/parallel/#Base.Channel)s with its API. This is threadsafe and thus should be preferred for multithreading applications.
2. Using `Resource` is a second possibility to model shared resources. Its interface gives more flexibility and is faster in single threaded applications, but in multithreading the user must avoid race conditions by explicitly wrapping access with `lock -… access …- unlock`.

```@docs
Resource
capacity
isfull
isready
isempty
empty!
length
push!
pop!
pushfirst!
popfirst!
first
last
```

`Resource` provides a `lock-unlock` API for multithreading applications.
```@docs
lock
unlock
islocked
trylock
```
