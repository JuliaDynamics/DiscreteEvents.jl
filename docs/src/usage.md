# User guide

## Installation

```@meta
CurrentModule = Simulate
```

`Simulate.jl` runs on Julia versions ≥ v"1.0". The current stable, registered version is installed with

```julia
pkg> add Simulate
```

The development version is installed with:

```julia
pkg> add("https://github.com/pbayer/Simulate.jl")
```

The package is then loaded with

```@repl usage
using Simulate
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

All given expressions or functions are then evaluated at a given simulation time or when during simulation the given conditions become true.

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
tau(::Clock, ::Symbol, ::Union{Number,Symbol})
@tau(::Any, ::Symbol, ::Union{Number, QuoteNode})
val
@val
```

## Processes

Julia functions can be registered and run as processes if they have an input and an output channel as their first two arguments. They follow another (the process-oriented) scheme and can be suspended and reactivated by the scheduler if they wait for something or delay. They must not (but are free to) handle and create events explicitly.

```@docs
SimProcess
@SP
SimException
process!
interrupt!
stop!(::SimProcess, ::SEvent)
```

### Delay and wait …

Processes must not handle their events explicitly, but can call `delay!` or `wait!` or `take!` and `put!` … on their channels. This usually comes in handy. They are then suspended until certain conditions are met or requested resources are available.

```@docs
delay!
wait!
```

### Now

If processes want IO-operations to finish before letting the clock proceed, they can enclose those operations in a `now!` call.

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

## Logging

A `Logger` allows to register variables and to record their states on demand.
The last record is stored in the logging variable. According to the Logger's state it can be printed or stored in a table.

### Example

```@repl usage
sim = Clock(); # create a clock
l = Logger(); # create a logging variable
init!(l, sim); # initialize the logger
(a, b, c) = 1, 1, 1 # create some variables
setup!(l, [:a, :b, :c], scope = m); # register them for logging
record!(l) # record the variables with the current clock time
l.last # show the last record
function f()  # a function for increasing and recording the variables
  global a += 1
  global b = a^2
  global c = a^3
  record!(l)
end
switch!(l, 1); # switch logger to printing
f() # increase and record the variables
switch!(l, 2); # switch logger to storing in data table
for i in 1:10 # create some events
    event!(sim, :(f()), i, scope = m)
end
run!(sim, 10) # run a simulation
l.df # view the recorded values
```

### Types

```@docs
Logger
```

### Functions

```@docs
init!
setup!
switch!
record!
clear!
```
