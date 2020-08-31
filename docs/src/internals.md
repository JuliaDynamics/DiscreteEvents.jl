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

## Clocks

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
ac2.clock             # access the parallel clock 2
```

`Schedule` and `ClockChannel` are two important `Clock` substructures:

```@docs
Schedule
ClockChannel
```

## Clock concurrency

If a task after activation by the clock gives control back to the Julia scheduler (e.g. by reading from a channel or by doing an IO-operation), it enqueues for its next schedule behind the clock. The clock may then increment time to ``t_{i+1}`` before the task can finish its job at current event time ``t_i``.

There are several ways to solve this problem:

1. The clock does a 2ⁿᵈ `yield()` after invoking a task and enqueues again at the end of the scheduling queue. This is implemented for `delay!` and `wait!` of processes and should be enough for most those cases.
2. Actors `push!` their message channel to the `clock.channels` vector and the clock will only proceed to the next event if all registered channels are empty [^1].
3. Tasks use `now!` to let the (master) clock do IO-operations for them. They can also `print` via the clock.

## Error handling and diagnosis

```@docs
prettyClock
```

[^1]: In [`YAActL`](https://github.com/pbayer/YAActL.jl) you can  `register!` to a `Vector{Channel}`. To register actors is also useful for diagnosis.
