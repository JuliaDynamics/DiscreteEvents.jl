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

Clocks schedule and execute *events*. They make given computations happen at a specified time (or under specified conditions).

- `Clock`s have virtual time and precede as fast as possible when they simulate chains of events. For parallel simulations they can control [`ActiveClock`](@ref)s on parallel threads.
- `RTClock`s schedule and execute events on a real (system) time line.

Clocks have an identification number:

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

You can create a clock with parallel active clocks on all available threads or fork existing clocks to other threads or collapse them if no longer needed. You can get direct access to parallel [`ActiveClock`](@ref)s and diagnose them.

```@docs
PClock
fork!
pclock
collapse!
diagnose
createRTClock
stopRTClock
```

## Events

Julia functions and expressions can be scheduled as *actions* for execution

1. at given clock times and
2. under specified conditions.

```@docs
Action
Timing
fun
event!
```

Actions can be scheduled on single or in tuples, even mixed:

```julia
function events()
    event!(:(i += 1), after, 10)  # one expression
    event!(fun(f, 1, 2, 3, diff=pi), every, 1)  # one fun
    event!((:(i += 1), fun(g, j)), (()->tau() ≥ 50, fun(isready, input), :(a ≤ 10))) # two funs under three conditions
end
```

Actions are called or evaluated at a their scheduled times or by sampling when their preconditions become true.

!!! note "Use inequalities to express conditions"

    For conditions you should prefer inequalities like <, ≤, ≥, > to equality == in order to make sure that a condition can be detected, e.g. `tau() ≥ 100` is preferable to `tau() == 100`.

## Continuous sampling

Actions can register for sampling and are then executed "continuously" at each clock increment Δt. The default clock sample rate Δt is 0.01 time units.

```@docs
sample_time!
periodic!
```

## Processes

Processes are typical event sequences implemented in a function. They
run as asynchronous tasks and get registered to a clock.

```@docs
Prc
process!
interrupt!
```

### Delay and wait …

In order to implement a process (an event sequence) functions can call `delay!` or `wait!` on the clock or `take!` and `put!` on  channels. They are then suspended until a given time or until certain conditions are met or requested resources are available.

```@docs
delay!
wait!
```

### Now

Processes (or asynchronous tasks in general) transfer IO-operations with a `now!` call to the clock so that they get executed at the current clock time.

```@docs
now!
```

## Actors

[Actors](https://en.wikipedia.org/wiki/Actor_model) can operate as finite state machines and are more reactive than processes. They run as Julia tasks listening to a (message) channel.

In order to integrate into the `DiscreteEvents` framework, they can `push!` their channels to the `clock.channel` vector. Then the clock will only proceed to the next event if all pushed channels are empty and the associated actors have finished processing the current event.

!!! note "Actor support is minimal"

    `DiscreteEvents` currently does not provide more actor support. See the [companion site](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/actors/) for code examples with actors.

## Running simulations

Virtual clocks can be run, stopped or stepped through and thereby used to simulate chains of events.

```@docs
run!
incr!
resetClock!
stop!
resume!
sync!
```

## Resources

Shared resources with limited capacity are often needed in simulations.

1. One approach to model them, is to use Julia [`Channel`](https://docs.julialang.org/en/v1/base/parallel/#Base.Channel)s with their API. This is thread-safe and thus should be preferred for multithreading applications.
2. Using `Resource` is a second possibility to model shared resources. Its interface gives more flexibility and is faster in single threaded applications, but in multithreading the user must avoid race conditions by explicitly wrapping access with `lock -… access …- unlock` – if the resources are shared by multiple tasks.

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

## Utilities

```@docs
onthread
```
