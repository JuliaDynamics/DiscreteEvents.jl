# User guide

## Installation

```@meta
CurrentModule = Simulate
```

`Simulate.jl` is not yet an registered package and is installed with

```julia
pkg> add("https://github.com/pbayer/jl")
```

The package is then loaded with

```@repl usage
using Simulate
```

## Modeling

Before we can do a simulation, we have to develop a model. Apart from Julia expressions and functions we have four elements here:

- a clock,
- events,
- processes and
- sampling

## The clock

The clock is central to any model and simulation, since it establishes the timeline. Here the clock contains not only the time, but also the time unit, all scheduled events, conditional events, processes, sampling expressions or functions and the sample rate Δt.

```@docs
Clock
```

We introduce a central clock 𝐶, can set time units and query the current simulation time.

```@docs
𝐶
setUnit!
τ
```

## Events

Julia expressions and functions can be scheduled on the clock's timeline to be executed later at a given simulation time or under given conditions which may become true during simulation. Thereby expressions and functions can be mixed or given in an array or tuple to an event or to a event condition.

```@docs
Timing
SimExpr
SimFunction
event!
```

## Processes

Julia functions can be registered and run as processes if they have an input and an output channel as their first two arguments. They follow another (the process-oriented) scheme and can be suspended and reactivated by the scheduler if they wait for something or delay. They must not (but are free to) handle and create events explicitly.

```@docs
SimProcess
SimException
process!
delay!
```

!!! note
    Functions running as processes operate in a loop. They have to give back control
    to other processes by e.g. doing a `take!(input)` on its input channel or by calling
    `delay!` etc., which will `yield` them. Otherwise they will after start starve
    everything else!

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
start!
incr!
run!
stop!
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
