# Actors

```@meta
CurrentModule = DiscreteEvents
```

[Actors](https://en.wikipedia.org/wiki/Actor_model) can operate as finite state machines, are more reactive than processes and can assemble into systems. They run as Julia tasks listening to a (message) channel. In order to integrate into the `DiscreteEvents` framework, they can register their channels to the `clock.channels` vector. Then the clock will only proceed to the next event if all registered channels are empty and the associated actors have finished to process the current event.

## Reactive programming

!!! warning "Don't use `delay!` or `wait!` with actors"

    Those are blocking operations and will make an actor non-responsive, just as a process.

Even if actors have registered their message channel to the clock, they should use [`now!`](@ref) for IO-operations or print via the clock. This also makes them more responsive and does not yield them to the scheduler during their loop.

## Actor potential

See the [companion site](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/actors/) for code examples with actors and [`YAActL`](https://pbayer.github.io/YAActL.jl/dev/). `YAActL` provides `register!` for integration into the `DiscreteEvents` framework.

Despite of minimal actor support, a lot can be done yet with actors. Actors push the boundaries of discrete event simulation.
