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

### Types

```@docs
Clock
timing
```

### Functions
```@docs
now
sample_time!
event!,
sample!
incr!
run!
stop!
resume!
```

## Logging

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
