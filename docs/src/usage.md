# User guide

`Sim.jl` is not yet an registered package and is installed with

```
pkg> add("https://github.com/pbayer/Sim.jl")
```

The package is then loaded with

```julia
julia> using Sim
```

## Modeling and simulation

A `Clock` allows the definition of scheduled events and sampling actions, which occur at predefined ticks. When we `run!` the `Clock`, it fires the events at their scheduled times and executes the sampling actions at each tick.

### Types

```@docs
Clock
Timing
```

### Functions
```@docs
now
sample_time!
event!
sample!
incr!
run!
stop!
resume!
```

## Logging

A `Logger` allows to register variables and to record their states on demand.
The last record is stored in the logging variable. According to the Logger's state it can be printed or stored in a table.

```julia
julia> sim = Clock(); # create a clock

julia> l = Logger(); # create a logging variable

julia> init!(l, sim); # initialize the logger

julia> setup!(l, [:a, :b, :c]); # register the variables a, b, c for logging

julia> record!(l); # record the variables with the current clock time
```

### Types
```@docs
Logger
Record
```

### Functions
```@docs
switch!
setup!
init!
record!
clear!
```

The recorded values can be accessed with

```julia
julia> l.last
(time = 0.0, a = 0, b = 0, c = 0)

julia> l.df
5×4 DataFrames.DataFrame
│ Row │ time    │ a     │ b     │ c     │
│     │ Float64 │ Int64 │ Int64 │ Int64 │
├─────┼─────────┼───────┼───────┼───────┤
│ 1   │ 0.0     │ 10    │ 100   │ 1331  │
│ 2   │ 0.0     │ 10    │ 100   │ 1728  │
│ 3   │ 0.0     │ 10    │ 100   │ 2197  │
│ 4   │ 0.0     │ 10    │ 100   │ 2744  │
│ 5   │ 0.0     │ 10    │ 100   │ 3375  │
```
