# Simulate.jl

A Julia package for discrete event simulation.

`Simulate.jl` supports different approaches to modeling and simulation of discrete event systems (DES). It provides three major schemes:

- event-scheduling scheme,
- process-oriented scheme and
- continuous sampling.

With them different modeling strategies can be applied.

## A first example

A server takes something from its input and puts it out modified after some time. We implement that in a function, create input and output channels and some "foo" and "bar" processes operating reciprocally on the channels:  

```julia
using Simulate, Printf
reset!(𝐶) # reset the central clock

# describe the activity of the server
function serve(input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    @printf("%5.2f: %s %d took token %d\n", tau(), name, id, token)
    delay!(rand())               # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create, register and start 8 SimProcesses (alias SP)
    process!(SP(i, serve, ch1, ch2, "foo", i, +))
    process!(SP(i+1, serve, ch2, ch1, "bar", i+1, *))
end

put!(ch1, 1)  # put first token into channel 1

run!(𝐶, 10)   # and run for 10 time units
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

**Author:** Paul Bayer
**License:** MIT

## Changes in v0.2.0 (development)

- functions and macros for defining conditions
- conditional `wait!(cond)`
- conditional events with `event!(sim, ex, cond)` are executed when the conditions are met,
- `event!` can be called without the first clock argument, it then goes to `𝐶`,
- `event!` takes an expression or a SimFunction or a tuple or an array of them,
- introduced aliases: `SF` for `SimFunction` and `SP` for `SimProcess`
- introduced process-based simulation with `SimProcess` and `process!`,
- extensive documentation,
- more examples,
