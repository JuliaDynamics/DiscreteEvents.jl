# Processes

Processes are *typical event sequences* running as asynchronous tasks.

## Process Setup

To setup a process, you

1. implement it in a function taking a [`Clock`](@ref) variable as its first argument,
2. specify the process id and its arguments with `Prc`,
3. start it as an asynchronous task and register it to a clock with `process!`.

```@docs
Prc
process!
```

## Delay and Wait …

Functions implementing processes create events implicitly by calling `delay!` or `wait!` on their clock. They wait for resources to be available by using [`take!`](https://docs.julialang.org/en/v1/base/parallel/#Base.take!-Tuple{Channel}) and [`put!`](https://docs.julialang.org/en/v1/base/parallel/#Base.put!-Tuple{Channel,Any}) on  channels. Those calls will suspend an asynchronous task until a given time or until certain conditions are met or requested resources are available.

```@docs
delay!
wait!
```

## Interrupts

If other events (e.g. representing reneging customers, failures) interrupt the typical event sequence of a process, it is waiting for a time or condition or resource and not ready to respond to something else. Processes therefore must use exception handling to handle unexpected events.

```@docs
PrcException
interrupt!
```

An [example at `DiscreteEventsCompanion`](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/examples/queue_mmc_srv_fail/) illustrates how to handle interrupts to a process. Things can get messy quickly if there are several unusual events which have to be handled in a process.

## Now

Processes (or asynchronous tasks in general) transfer IO-operations with a `now!` call to the (master) clock to ensure they get executed at current clock time. As a convenience you can print directly to the clock.

```@docs
now!
print(::Clock, ::IO, ::Any, ::Any)
println(::Clock, ::IO, ::Any, ::Any)
```

## Examples

The [A-B Call Center Problem](@ref a-b_call_center) illustrates how to implement and setup a process. You can find [more examples at `DiscreteEventsCompanion`](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/examples/examples/#Examples).
