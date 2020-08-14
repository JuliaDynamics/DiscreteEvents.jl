# Internals

```@meta
CurrentModule = DiscreteEvents
```

The following types are handled internally by `DiscreteEvents.jl`, but are necessary for analyzing and debugging clocks and event schedules.

## Events

```@docs
AbstractEvent
DiscreteEvent
DiscreteCond
Sample
```

## Clock

```@docs
AbstractClock
ActiveClock
Schedule
ClockChannel
```

## Error handling and diagnosis

```@docs
ClockException
prettyClock
```
