# DiscreteEvents.jl

A Julia package for **discrete event generation and simulation**.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://pbayer.github.io/DiscreteEvents.jl/v0.2.0/)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://pbayer.github.io/DiscreteEvents.jl/dev)
[![Build Status](https://travis-ci.com/pbayer/DiscreteEvents.jl.svg?branch=master)](https://travis-ci.com/pbayer/DiscreteEvents.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/2emtqb9auk2y1fsh/branch/master?svg=true)](https://ci.appveyor.com/project/pbayer/discreteevents-jl/branch/master)
[![codecov](https://codecov.io/gh/pbayer/DiscreteEvents.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/DiscreteEvents.jl)
[![Coverage Status](https://coveralls.io/repos/github/pbayer/DiscreteEvents.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/DiscreteEvents.jl?branch=master)

`DiscreteEvents.jl` provides *three schemes* for modeling and simulating discrete event systems (DES): 1) event scheduling, 2) interacting processes and 3) continuous sampling. It introduces a *clock* and allows to schedule arbitrary Julia functions or expressions as *events*, *processes* or *sampling* operations on the clock's timeline. Thus it provides simplicity and flexibility in building models and performance in simulation.

## A first example

A server takes something from its input and puts it out modified after some time. We implement that in a function, create input and output channels and some "foo" and "bar" processes operating reciprocally on the channels:  

```julia
using DiscreteEvents, Printf, Random

function simple(c::Clock, input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    now!(c, SF(println, @sprintf("%5.2f: %s %d took token %d", tau(c), name, id, token)))
    d = delay!(c, rand())        # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

clk = Clock()      # create a clock
Random.seed!(123)  # seed the random number generator

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8     # create and register 8 SimProcesses SP
    process!(clk, SP(i, simple, ch1, ch2, "foo", i, +))
    process!(clk, SP(i+1, simple, ch2, ch1, "bar", i+1, *))
end

put!(ch1, 1)       # put first token into channel 1
yield()            # let the first task take it
run!(clk, 10)      # and run for 10 time units
```

If we source this program, it runs a simulation:

```julia
julia> include("docs/examples/channels.jl")
 0.00: foo 1 took token 1
 0.77: bar 2 took token 2
 1.71: foo 3 took token 4
 2.38: bar 4 took token 7
 2.78: foo 5 took token 28
 3.09: bar 6 took token 33
 ...
 ...
 7.64: foo 1 took token 631016
 7.91: bar 2 took token 631017
 8.36: foo 3 took token 1262034
 8.94: bar 4 took token 1262037
 9.20: foo 5 took token 5048148
 9.91: bar 6 took token 5048153
"run! finished with 43 clock events, 0 sample steps, simulation time: 10.0"
```

For further examples see the [documentation](https://pbayer.github.io/DiscreteEvents.jl/dev),  or the companion package [DiscreteEventsCompanion](https://github.com/pbayer/DiscreteEventsCompanion.jl).

## Installation

The development (and sometimes not so stable) version can be installed with:

```julia
pkg> add("https://github.com/pbayer/DiscreteEvents.jl")
```

The stable, registered version is installed with:

```julia
pkg> add DiscreteEvents
```

Please use, test and help to develop `DiscreteEvents.jl`! 😄

**Author:** Paul Bayer
