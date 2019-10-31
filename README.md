# Sim.jl

A Julia package for **discrete event simulation**. It introduces a **clock** and allows to schedule Julia expressions and functions as **events** for later execution on the clock's time line. If we **run** the clock, the events are executed in the scheduled sequence.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://pbayer.github.io/Sim.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://pbayer.github.io/Sim.jl/dev)
[![Build Status](https://travis-ci.com/pbayer/Sim.jl.svg?branch=master)](https://travis-ci.com/pbayer/Sim.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/pbayer/Sim.jl?svg=true)](https://ci.appveyor.com/project/pbayer/Sim-jl)
[![Codecov](https://codecov.io/gh/pbayer/Sim.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/Sim.jl)
[![Coverage Status](https://coveralls.io/repos/github/pbayer/Sim.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/Sim.jl?branch=master)

**Author:** Paul Bayer

**Documentation** is currently at https://pbayer.github.io/Sim.jl/dev

## Example: Two guys meet

We call the needed modules and define some types and data:

```julia
using Sim, Printf

struct Guy
    name
end

abstract type Encounter end
struct Meet <: Encounter
    someone
end
struct Greet <: Encounter
    num
    from
end
struct Response <: Encounter
    num
    from
end

comm = ("Nice to meet you!", "How are you?", "Have a nice day!", "bye bye")
```

We implement the behavior of the "guys" as `step!`-δ-functions of a state machine. For that we use some features of `Sim.jl`:

- italic `𝐶` (`\itC`+Tab) or `Clk` is the central clock,
- `SimFunction` prepares a Julia function for later execution,
- `event!` schedules it for execution `after` some time,
- `τ()` gives the central time (`𝐶.time`).


```julia
say(name, n) =  @printf("%5.2f s, %s: %s\n", τ(), name, comm[n])

function step!(me::Guy, σ::Meet)
    event!(𝐶, SimFunction(step!, σ.someone, Greet(1, me)), after, 2*rand())
    say(me.name, 1)
end

function step!(me::Guy, σ::Greet)
    if σ.num < 3
        event!(𝐶, SimFunction(step!, σ.from, Response(σ.num, me)), after, 2*rand())
        say(me.name, σ.num)
    else
        say(me.name, 4)
    end
end

function step!(me::Guy, σ::Response)
    event!(𝐶, SimFunction(step!, σ.from, Greet(σ.num+1, me)), after, 2*rand())
    say(me.name, σ.num+1)
end
```

Then we define some "guys" and a starting event and tell the clock `𝐶` to `run` for twenty "seconds":

```julia
foo = Guy("Foo")
bar = Guy("Bar")

event!(𝐶, SimFunction(step!, foo, Meet(bar)), at, 10*rand())
run!(𝐶, 20)
```

If we source this code, it will run a simulation:

```julia
julia> include("docs/examples/greeting.jl")
 7.30 s, Foo: Nice to meet you!
 8.00 s, Bar: Nice to meet you!
 9.15 s, Foo: How are you?
10.31 s, Bar: How are you?
11.55 s, Foo: Have a nice day!
12.79 s, Bar: bye bye
Finished: 6 events, simulation time: 20.0
```

Then we `reset` the clock `𝐶` for further simulations.

```julia
julia> reset!(𝐶)
clock reset to t₀=0, sampling rate Δt=0.
```
For further examples see [`docs/examples`](https://github.com/pbayer/Sim.jl/tree/master/docs/examples) or [`docs/notebooks`](https://github.com/pbayer/Sim.jl/tree/master/docs/notebooks).
