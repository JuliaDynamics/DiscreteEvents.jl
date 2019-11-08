# Simulate.jl

A Julia package for discrete event simulation.

`Simulate.jl` introduces a **clock** and allows to schedule Julia expressions and functions as **events** for later execution on the clock's time line. Expressions or functions can register for sampling and then are executed at each clock tick. Julia functions can also run as **processes**, which can refer to the clock, respond to events, delay etc. If we **run** the clock, the events are executed in the scheduled sequence.

## Installation

`Simulate.jl` is a registered package and is installed with:

```julia
pkg> add Simulate
```

The development (and sometimes not so stable version) can be installed with:

```julia
pkg> add("https://github.com/pbayer/Simulate.jl")
```

**Author:** Paul Bayer
**License:** MIT

## Process based example

```julia
using Simulate, Printf
reset!(𝐶) # reset the central clock

# a function with Channels in and out as the first  
# two arguments can be registered as a SimProcess
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

for i in 1:2:8    # create and register 8 SimProcesses to the clock
    process!(𝐶, SimProcess(i, foo, ch1, ch2, i))     # 4 foos
    process!(𝐶, SimProcess(i+1, bar, ch2, ch1, i+1)) # 4 bars
end

start!(𝐶) # start all registered processes
put!(ch1, 1) # put first token into channel 1

sleep(0.1) # give the processes some time to startup

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
