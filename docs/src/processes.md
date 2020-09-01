# Processes

Processes are *typical event sequences*. They get implemented in a function, run as asynchronous tasks in a loop and get registered to a clock.

```@docs
Prc
process!
```

!!! warning "Processes must yield!"

    A process has to give control back to Julia by e.g. doing a `take!(input)` or by calling [`delay!`](@ref) or [`wait!`](@ref). Otherwise it will starve everything else!

## Delay and wait …

In order to implement a process (an event sequence) functions can call `delay!` or `wait!` on the clock or `take!` and `put!` on  channels. They are then suspended until a given time or until certain conditions are met or requested resources are available.

```@docs
delay!
wait!
```

## Interrupts

If other events (customers reneging, failures) interrupt the typical event sequence of a process, it is blocked and not ready to respond. Processes therefore must use exception handling to handle unusual events.

```@docs
PrcException
interrupt!
```

An [example at `DiscreteEventsCompanion`](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/examples/queue_mmc_srv_fail/) illustrates how to handle interrupts to a process. Things can get messy quickly if there are several unusual events which have to be handled in a process.

## Now

Processes (or asynchronous tasks in general) transfer IO-operations with a `now!` call to the (master) clock so that they get executed at the current clock time. As a convenience you can print directly to the clock.

```@docs
now!
print(::Clock, ::IO, ::Any, ::Any)
println(::Clock, ::IO, ::Any, ::Any)
```
