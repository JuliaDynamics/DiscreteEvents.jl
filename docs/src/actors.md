# Actors

```@meta
CurrentModule = DiscreteEvents
```

Even if not considered in classical literature about DES, [Actors](https://en.wikipedia.org/wiki/Actor_model) are natural candidates to represent entities in discrete event systems. They are not bound to typical event sequences, can operate as finite state machines, can assemble into systems and represent hierarchies. They can be spawned to and interoperate over threads.

## Assumptions about Actors

[Actors](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/actors/#An-Operational-Definition) run as Julia tasks listening to a (message) channel. They block only if they have no message in their channel. Therefore they run in a simple loop, reacting to a message when it arrives according to their current state. They don't share their state with other Actors or their environment.

!!! warning "Don't use `delay!` or `wait!` with Actors"

    Those are blocking operations and will make an actor non-responsive, just as a process.

In order to integrate into the `DiscreteEvents` framework, Actors  register their channels to the `clock.channels` vector. Then the clock will only proceed to the next event if all registered channels are empty and the associated Actors have finished to process the current event.

Even if Actors have registered their message channel to the clock, they should use [`now!`](@ref) for IO-operations or print via the clock. This also makes them responsive and does not yield them to the scheduler during their loop.

## Actor potential

See the [companion site](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/actors/) for more explanations and examples with Actors. [`YAActL`](https://pbayer.github.io/YAActL.jl/dev/) provides `register!` for integration into the `DiscreteEvents` framework.

Despite of minimal actor support, a lot can be done yet with Actors. Actors push the boundaries of discrete event simulation.
