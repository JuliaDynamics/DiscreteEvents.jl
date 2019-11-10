# Simulate.jl

A new⭐ Julia package for **discrete event simulation**.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://pkg.julialang.org/docs/Simulate)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://pbayer.github.io/Simulate.jl/dev)
[![Build Status](https://travis-ci.com/pbayer/Simulate.jl.svg?branch=master)](https://travis-ci.com/pbayer/Simulate.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/p5trstrte9il7rm1/branch/master?svg=true)](https://ci.appveyor.com/project/pbayer/simulate-jl-ueug1/branch/master)
[![codecov](https://codecov.io/gh/pbayer/Simulate.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/Simulate.jl)
[![Coverage Status](https://coveralls.io/repos/github/pbayer/Simulate.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/Simulate.jl?branch=master)

**Development Documentation** is at https://pbayer.github.io/Simulate.jl/dev

`Simulate.jl` introduces a **clock** and allows to schedule Julia expressions and functions as **discrete events** for later execution on the clock's time line. Expressions or functions can register for **continuous sampling** and then are executed at each clock tick. Julia functions can also run as **processes**, which can refer to the clock, respond to events, delay etc. If we **run** the clock,  events are executed in the scheduled sequence, sampling functions are called continuously at each clock tick and processes are served accordingly.

## Installation

The development (and sometimes not so stable) version can be installed with:

```julia
pkg> add("https://github.com/pbayer/Simulate.jl")
```

The stable, registered version is installed with:

```julia
pkg> add Simulate
```


## Approaches to discrete event simulation

`Simulate.jl` supports four major approaches to modeling and simulation of discrete event systems (DES):

1. **event based**: *events* occur in time and trigger actions causing further events …
2. **state based**: entities react to events occurring in time depending on their current *state*. Their actions may cause further events …
3. **activity based**: *activities* occur in time and cause other activities …
4. **process based**: entities are modeled as *processes* waiting for
events and then acting according to the event and their current state …

The first three approaches are enabled with `event!` and `SimFunction` of Simulate.jl v0.1.0 (released). 0.2.0 (current master) is still a bit experimental and supports  process based modeling and simulation with `SimProcess` and `process!`. `Simulate.jl`'s aim is to allow the four approaches to be combined in a consistent framework.

## Process based example

```julia
using Simulate, Printf
reset!(𝐶) # reset the central clock

# a function with Channels input and output as the first
# two arguments can be registered as a SimProcess
# the function is put in a loop, so no need to have a loop here
function simple(input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    @printf("%5.2f: %s %d took token %d\n", τ(), name, id, token)
    d = delay!(rand())           # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create and register 8 SimProcesses
    process!(𝐶, SimProcess(i, simple, ch1, ch2, "foo", i, +))
    process!(𝐶, SimProcess(i+1, simple, ch2, ch1, "bar", i+1, *))
end

start!(𝐶)     # start all registered processes
put!(ch1, 1)  # put first token into channel 1

sleep(0.1)    # give the processes some time to startup

run!(𝐶, 10)   # an run for 10 time units
```

If we source this program, it runs a simulation:

```julia
julia> include("docs/examples/channels.jl")
 0.00: foo 7 took token 1
 0.25: bar 4 took token 8
 0.29: foo 3 took token 32
 0.55: bar 2 took token 35
 1.21: foo 5 took token 70
 1.33: bar 8 took token 75
 1.47: foo 1 took token 600
 1.57: bar 6 took token 601
 2.07: foo 7 took token 3606
 3.00: bar 4 took token 3613
 3.68: foo 3 took token 14452
 4.33: bar 2 took token 14455
 5.22: foo 5 took token 28910
 6.10: bar 8 took token 28915
 6.50: foo 1 took token 231320
 6.57: bar 6 took token 231321
 7.13: foo 7 took token 1387926
 8.05: bar 4 took token 1387933
 8.90: foo 3 took token 5551732
 9.10: bar 2 took token 5551735
 9.71: foo 5 took token 11103470
 9.97: bar 8 took token 11103475
10.09: foo 1 took token 88827800
"run! finished with 22 events, simulation time: 10.0"
```

Please use, test and help to develop `Simulate.jl`! 😄

For further examples see [`docs/examples`](https://github.com/pbayer/Simulate.jl/tree/master/docs/examples) or [`docs/notebooks`](https://github.com/pbayer/Simulate.jl/tree/master/docs/notebooks).

**Author:** Paul Bayer
