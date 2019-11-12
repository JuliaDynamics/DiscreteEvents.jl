# Simulate.jl

A Julia package for discrete event simulation.

`Simulate.jl` introduces a **clock** and allows to schedule Julia expressions and functions as **discrete events** for later execution on the clock's time line. Expressions or functions can register for **continuous sampling** and then are executed at each clock tick. Julia functions can also run as **processes**, which can refer to the clock, respond to events, delay etc. If we **run** the clock,  events are executed in the scheduled sequence, sampling functions are called continuously at each clock tick and processes are served accordingly.

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
...
...
 8.90: foo 3 took token 5551732
 9.10: bar 2 took token 5551735
 9.71: foo 5 took token 11103470
 9.97: bar 8 took token 11103475
10.09: foo 1 took token 88827800
"run! finished with 22 events, simulation time: 10.0"
```

For further examples see [`docs/examples`](https://github.com/pbayer/Simulate.jl/tree/master/docs/examples) or [`docs/notebooks`](https://github.com/pbayer/Simulate.jl/tree/master/docs/notebooks).

## Changes in v0.2.0 (development)

- **next** conditional `wait!(cond)`
- conditional events with `event!(sim, ex, cond)` are executed when the conditions are met,
- `event!` can be called without the first clock argument, it then goes to `𝐶`,
- `event!` takes an expression or a SimFunction or a tuple or an array of them,
- introduced aliases: `𝐅` for `SimFunction` and `𝐏` for `SimProcess`
- introduced process-based simulation with `SimProcess` and `process!`,
- extensive documentation,
- more examples,
