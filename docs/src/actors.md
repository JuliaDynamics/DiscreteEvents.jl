# Actors

[Actors](https://en.wikipedia.org/wiki/Actor_model) can operate as finite state machines, are more reactive than processes and can assemble into systems. They run as Julia tasks listening to a (message) channel. In order to integrate into the `DiscreteEvents` framework, they can register their channels to the `clock.channels` vector. Then the clock will only proceed to the next event if all registered channels are empty and the associated actors have finished to process the current event.

!!! note "Actor support is minimal"

    See the [companion site](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/actors/) for code examples with actors and [`YAActL`](https://github.com/pbayer/YAActL.jl). `YAActL` provides `register!` for integration into the `DiscreteEvents` framework.

!!! warning "Don't use `delay!` or `wait!` with actors"

    Those are blocking operations and will make an actor non-responsive, just as a process.

Despite of minimal actor support a lot can be done yet with actors. Actors push the boundaries of discrete event simulation.
