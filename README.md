# Simulate.jl

A Julia package for **discrete event simulation**. It introduces a **clock** and allows to schedule Julia expressions and functions as **events** for later execution on the clock's time line. If we **run** the clock, the events are executed in the scheduled sequence. Julia functions can also run as **processes**, which can refer to the clock, respond to events, delay etc.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://pbayer.github.io/Simulate.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://pbayer.github.io/Simulate.jl/dev)
[![Build Status](https://travis-ci.com/pbayer/Simulate.jl.svg?branch=dev)](https://travis-ci.com/pbayer/Simulate.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/p5trstrte9il7rm1/branch/dev?svg=true)](https://ci.appveyor.com/project/pbayer/simulate-jl-ueug1/branch/dev)
[![codecov](https://codecov.io/gh/pbayer/Simulate.jl/branch/dev/graph/badge.svg)](https://codecov.io/gh/pbayer/Simulate.jl)
[![Coverage Status](https://coveralls.io/repos/github/pbayer/Simulate.jl/badge.svg?branch=dev)](https://coveralls.io/github/pbayer/Simulate.jl?branch=dev)

**Author:** Paul Bayer

**Development Documentation** is currently at https://pbayer.github.io/Simulate.jl/dev

## A pragmatic approach to simulation

I want to develop `Simulate.jl` to support four major approaches to modeling and simulation of discrete event systems (DES):

1. **event based**: events occur in time and trigger actions, which may
cause further events …
2. **activity based**: activities occur in time and cause other activities …
3. **state based**: events occur in time and trigger actions of entities (e.g. state machines) depending on their current state, those actions may cause further events …
4. **process based**: entities in a DES are modeled as processes waiting for
events and then acting according to the event and their current state …

With the current main two simulation hooks of `Simulate.jl`: `event!` and `SimFunction` the first three approaches are supported. Now I introduce also process based modeling and simulation. `SimProcess` and `process!` are still a bit experimental and look like that:

## Example (process based)

```julia
using Simulate, Printf
reset!(𝐶)

function foo(in::Channel, out::Channel, id)
    token = take!(in)
    @printf("%5.2f: foo %d took token %d\n", τ(), id, token)
    d = delay!(rand())
    put!(out, token+id)
end

function bar(in::Channel, out::Channel, id)
    token = take!(in)
    @printf("%5.2f: bar %d took token %d\n", τ(), id, token)
    d = delay!(rand())
    put!(out, token*id)
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create and register 8 SimProcesses
    process!(𝐶, SimProcess(i, foo, ch1, ch2, i))     # 4 foos
    process!(𝐶, SimProcess(i+1, bar, ch2, ch1, i+1)) # 4 bars
end

start!(𝐶) # start all registered processes
put!(ch1, 1) # put first token into channel 1

sleep(0.1) # we give the processes some time to startup

run!(𝐶, 10)
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

For further examples see [`docs/examples`](https://github.com/pbayer/Simulate.jl/tree/master/docs/examples) or [`docs/notebooks`](https://github.com/pbayer/Simulate.jl/tree/master/docs/notebooks).
