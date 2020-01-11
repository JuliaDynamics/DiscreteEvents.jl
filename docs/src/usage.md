# User guide

## Installation

```@meta
CurrentModule = Simulate
```

`Simulate.jl` runs on Julia versions ≥ v"1.0".

```@docs
Simulate
version
```

## The clock

```@docs
Clock
```

The central clock  is 𝐶. You can set time units and query the current simulation time.

```@docs
𝐶
setUnit!
tau(::Clock)
@tau(::Clock)
```

## Events

Events are scheduled on the clock's timeline and are triggered at a given simulation time or under conditions which may become true during simulation.

### Expressions and functions as events and conditions

Julia expressions and functions can be scheduled as events.

```@docs
Timing
SimFunction
@SF
SimExpr
```

SimFunctions and expressions can be given to events on their own or in arrays or tuples, even mixed:

```julia
function events()
    event!(:(i += 1), after, 10)  # one expression
    event!(SF(f, 1, 2, 3, diff=pi), every, 1)  # one SimFunction
    event!((:(i += 1), SF(g, j)), [:(tau() ≥ 50), SF(isready, input), :(a ≤ 10)]) # two SimExpr under three conditions
end
```

All given functions or expressions are then called or evaluated at a given simulation time or when during simulation the given conditions become true.

!!! warning
    Evaluating expressions or symbols at global scope is much slower than using
    `SimFunction`s and gives a one time warning. See [Performance](performance.md).
    This functionality may be removed entirely in a future version. (Please write
    an [issue](https://github.com/pbayer/Simulate.jl/issues) if you want to keep it.)

### Timed events

SimFunctions and expressions can be scheduled for execution at given clock times.

```@docs
event!(::Clock, ::Union{SimExpr, Array, Tuple}, ::Number)
```

As a convenience the `Timing` can be also choosen using `at`, `after` or `every` `t`.

```@docs
event!(::Clock, ::Union{SimExpr, Array, Tuple}, ::Timing, ::Number)
```

### Conditional events

They are evaluated at each clock tick (like sampling functions) and are fired when all conditions are met.

```@docs
event!(::Clock, ::Union{SimExpr, Array, Tuple}, ::Union{SimExpr, Array, Tuple})
```

!!! note
    Since conditions often are not met exactly you should prefer inequalities like <, ≤, ≥, > to equality == in order to get sure that a fulfilled condition can be detected, e.g. ``:(tau() ≥ 100)`` is preferable to ``:(tau() == 100)``.

There are some helper functions and macros for defining conditions. It is usually
more convenient to use the macros since the generate the necessary SimFunctions
directly:

```@docs
tau(::Clock, ::Function, ::Union{Number,Symbol})
@tau(::Any, ::QuoteNode, ::Union{Number, QuoteNode})
val
@val
```

## Processes

Julia functions can be registered and run as processes. They follow another (the process-oriented) scheme and can be suspended and reactivated by the scheduler if they wait for something or delay. They must not (but are free to) handle and create events explicitly.

```@docs
SimProcess
@SP
SimException
process!
interrupt!
stop!(::SimProcess, ::SEvent)
```

### Delay and wait …

Processes do not need to handle their events explicitly, but can call `delay!` or `wait!` or `take!` and `put!` … on their channels. This usually comes in handy. They are then suspended until certain conditions are met or requested resources are available.

```@docs
delay!
wait!
```

### Now

Processes in a simulation want their IO-operations to finish before the clock proceeds. Therefore they must enclose those operations in a `now!` call.

```@docs
now!
```

## Continuous sampling

Functions or expressions can register for sampling and are then executed "continuously" at each clock increment Δt.

```@docs
sample_time!
sample!
```

## Running simulations

If we run the clock, events are triggered, conditions are evaluated, sampling is done and delays are executed … Thus we run a simulation. We can also step through a simulation or stop and resume a clock, reset ist and so on.

```@docs
reset!
incr!
run!
stop!(::Clock)
resume!
sync!
```
