# Internals

```@meta
CurrentModule = DiscreteEvents
```

The following types are handled internally by `DiscreteEvents.jl`, but maybe necessary for analyzing and debugging clocks and event schedules.

## Events

```@docs
AbstractEvent
DiscreteEvent
DiscreteCond
Sample
```

## Clock

There is an abstract type for clocks and an active clock, used for controlling parallel clocks.

```@docs
AbstractClock
GlobalClock
ActiveClock
LocalClock
localClock
```

**An example on active clocks:**

```@repl
using DiscreteEvents
clk = Clock()         # create a clock
fork!(clk)            # fork it to parallel threads
clk                   # now you see parallel active clocks
clk = PClock()        # create a parallel clock structure
ac2 = pclock(clk, 2)  # get access to the active clock on thread 2
ac2.clock             # not recommended, access the parallel clock 2
```

`Schedule` and `ClockChannel` are `Clock` substructures:

```@docs
Schedule
ClockChannel
```

## Error handling and diagnosis

```@docs
ClockException
prettyClock
```
