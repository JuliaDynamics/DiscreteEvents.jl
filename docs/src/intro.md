# Introduction

`Simulate.jl` supports different approaches to modeling and simulation of discrete event systems (DES). It provides three major schemes:

- event-scheduling scheme,
- process-oriented scheme and
- continuous sampling.

With them different modeling strategies can be applied.

## A first example (process-oriented)

A server takes something from its input and puts it out modified after some time. We implement that in a function, create input and output channels and some "foo" and "bar" processes operating reciprocally on the channels:  

```julia
using Simulate, Printf
reset!(𝐶) # reset the central clock

# a function with input and output channels as the first
# two arguments can run as a SimProcess.
# Then it runs in a loop, so no need to have a loop here
function serve(input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    @printf("%5.2f: %s %d took token %d\n", τ(), name, id, token)
    delay!(rand())               # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create and register 8 SimProcesses (alias 𝐏)
    process!(𝐏(i, serve, ch1, ch2, "foo", i, +))
    process!(𝐏(i+1, serve, ch2, ch1, "bar", i+1, *))
end

start!(𝐶)     # start all processes, registered to the central clock 𝐶
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
...
...
 8.90: foo 3 took token 5551732
 9.10: bar 2 took token 5551735
 9.71: foo 5 took token 11103470
 9.97: bar 8 took token 11103475
10.09: foo 1 took token 88827800
"run! finished with 22 clock events, simulation time: 10.0"
```

For further examples see [`docs/examples`](https://github.com/pbayer/Simulate.jl/tree/master/docs/examples) or [`docs/notebooks`](https://github.com/pbayer/Simulate.jl/tree/master/docs/notebooks).
