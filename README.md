# Sim.jl

A Julia package for discrete event simulation.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://pbayer.github.io/Sim.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://pbayer.github.io/Sim.jl/dev)
[![Build Status](https://travis-ci.com/pbayer/Sim.jl.svg?branch=master)](https://travis-ci.com/pbayer/Sim.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/pbayer/Sim.jl?svg=true)](https://ci.appveyor.com/project/pbayer/Sim-jl)
[![Codecov](https://codecov.io/gh/pbayer/Sim.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/Sim.jl)
[![Coverage Status](https://coveralls.io/repos/github/pbayer/Sim.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/Sim.jl?branch=master)

**Author:** Paul Bayer

**Documentation** is currently at https://pbayer.github.io/Sim.jl/dev

## Example: Two guys meet

```julia
using Sim, Printf

struct Guy
    name
end

abstract type Encounter end # we define some events
struct Meet <: Encounter
    someone
end
struct Greet <: Encounter
    type
    from
end
struct Response <: Encounter
    type
    from
end

comm = ("Nice to meet you!", "How are you?", "Have a nice day!", "bye bye")
say(name, n) =  @printf("%5.2f s, %s: %s\n", now(sim), name, comm[n])

function step!(me::Guy, σ::Meet) # the step! functions realize a state machine
    event!(sim, SimFunction(step!, σ.someone, Greet(1, me)), after, 2*rand())
    say(me.name, 1)
end

function step!(me::Guy, σ::Greet)
    if σ.type < 3
        event!(sim, SimFunction(step!, σ.from, Response(σ.type, me)), after, 2*rand())
        say(me.name, σ.type)
    else
        say(me.name, 4)
    end
end

function step!(me::Guy, σ::Response)
    event!(sim, SimFunction(step!, σ.from, Greet(σ.type+1, me)), after, 2*rand())
    say(me.name, σ.type+1)
end

sim = Clock()
foo = Guy("Foo")
bar = Guy("Bar")

event!(sim, SimFunction(step!, foo, Meet(bar)), at, 10*rand()) # 1st event
run!(sim, 20)
```

If we source this code it will run a simulation:

```julia
julia> include("greeting.jl")
 5.65 s, Foo: Nice to meet you!
 5.97 s, Bar: Nice to meet you!
 7.18 s, Foo: How are you?
 8.46 s, Bar: How are you?
 9.39 s, Foo: Have a nice day!
11.30 s, Bar: bye bye
Finished: 6 events, simulation time: 20.0
```

More description of this example is in the [notebook](https://nbviewer.jupyter.org/github/pbayer/Sim.jl/blob/master/docs/notebooks/greeting.ipynb). For further examples see [`docs/examples`](https://github.com/pbayer/Sim.jl/tree/master/docs/examples) or [`docs/notebooks`](https://github.com/pbayer/Sim.jl/tree/master/docs/notebooks).
