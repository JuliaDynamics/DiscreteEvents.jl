# User guide

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

## Modeling and simulation

A virtual `Clock` allows to schedule Julia functions or expressions as timed events or as sampling actions, which occur at predefined clock ticks. When we `run` the `Clock`, it fires the events at their scheduled times and executes the sampling actions at each tick.

### Silly example

```@repl usage
m = @__MODULE__ # catching the current module is needed for documentation
using Printf
comm = ["Hi, nice to meet you!", "How are you?", "Have a nice day!"];
greet(name, n) =  @printf("%5.2f s, %s: %s\n", τ(), name, comm[n])
function foo(n) # 1st passerby
    greet("Foo", n)
    event!(𝐶, :(bar($n)), after, 2*rand(), scope = m)
end
function bar(n) # 2nd passerby
    greet("Bar", n)
    if n < 3
       event!(𝐶, :(foo($n+1)), after, 2*rand(), scope = m)
    else
       println("bye bye")
    end
end
event!(𝐶, :(foo(1)), at, 10*rand(), scope = m); # create an event for a start
run!(𝐶, 20) # and run the simulation
```

## Types and constants

```@docs
Clock
Timing
SimFunction
SimProcess
SimException
```

## Central time
```@docs
𝐶
```

## Functions

```@docs
setUnit!
τ
sample_time!
event!
sample!
process!
delay!
start!
incr!
run!
stop!
resume!
sync!
reset!
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
