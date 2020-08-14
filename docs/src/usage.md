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

Clocks schedule and execute *actions*, computations that happen as *events* at specified times (or under specified conditions).

- `Clock`s have virtual time and precede as fast as possible. They can control [`ActiveClock`](@ref)s on parallel threads to support parallel simulations.
- `RTClock`s schedule and execute actions on a real (system) time line.

Clocks have an identification number:

- a master `Clock` on thread 1 has id = 1,
- worker [`ActiveClock`](@ref)s on parallel threads have id > 1 identical with the thread number,
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

### Parallel clocks

You can create a clock with parallel active clocks on all available threads. Parallel operations (processes and actors) can get their local clock from it. 

```@docs
PClock
localClock
```

Furthermore you can fork existing clocks to other threads or collapse them if no longer needed. You can get direct access to parallel [`ActiveClock`](@ref)s and diagnose them.

```@docs
fork!
pclock
collapse!
diagnose
```

### Real time clocks

Real time clocks allow to schedule and execute events on a physical time line.

```@docs
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

Processes (or asynchronous tasks in general) transfer IO-operations with a `now!` call to the clock so that they get executed at the current clock time. As a convenience you can print directly to the
clock.

```@docs
now!
print(::Clock, ::Any)
println(::Clock, ::Any)
```

## Actors

[Actors](https://en.wikipedia.org/wiki/Actor_model) can operate as finite state machines, are more reactive than processes and can compose. They run as Julia tasks listening to a (message) channel. In order to integrate into the `DiscreteEvents` framework, they can `push!` their channels to the `clock.channel` vector. Then the clock will only proceed to the next event if all pushed channels are empty and the associated actors have finished processing the current event.

!!! note "Actor support is minimal"

    See the [companion site](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/actors/) for code examples with actors and [`YAActL`](https://github.com/pbayer/YAActL.jl). `YAActL` provides `register!` for integration into the `DiscreteEvents` framework.

Despite of minimal actor support a lot can be done yet with actors. Actors push the boundaries of discrete event simulation.

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
