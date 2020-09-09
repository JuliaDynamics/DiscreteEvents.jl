# DiscreteEvents.jl

A Julia package for **discrete event generation and simulation**.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://pbayer.github.io/DiscreteEvents.jl/stable/)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://pbayer.github.io/DiscreteEvents.jl/dev)
[![Build Status](https://travis-ci.com/pbayer/DiscreteEvents.jl.svg?branch=master)](https://travis-ci.com/pbayer/DiscreteEvents.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/2emtqb9auk2y1fsh/branch/master?svg=true)](https://ci.appveyor.com/project/pbayer/discreteevents-jl/branch/master)
[![codecov](https://codecov.io/gh/pbayer/DiscreteEvents.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/DiscreteEvents.jl)
[![Coverage Status](https://coveralls.io/repos/github/pbayer/DiscreteEvents.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/DiscreteEvents.jl?branch=master)

`DiscreteEvents.jl` <sup id="a1">[1](#f1)</sup>&ensp; introduces *clocks* and allows to schedule and execute arbitrary functions or expressions as *actions* on the clocks' timeline. It provides simple, yet powerful ways to model and simulate discrete event systems (DES).

## An M/M/3 queue

Three servers serve customers arriving at an arrival rate λ with a service rate μ. We implement `serve` and `arrive` functions, create a clock and queues, start three service processes and an arrival process and run.

```julia
using DiscreteEvents, Printf, Distributions, Random

# describe a server process
function serve(clk::Clock, id::Int, input::Channel, output::Channel, X::Distribution)
    job = take!(input)
    print(clk, @sprintf("%6.3f: server %d serving customer %d\n", tau(clk), id, job))
    delay!(clk, X)
    print(clk, @sprintf("%6.3f: server %d finished serving %d\n", tau(clk), id, job))
    put!(output, job)
end

# model the arrivals
function arrive(c::Clock, input::Channel, cust::Vector{Int})
    cust[1] += 1
    @printf("%6.3f: customer %d arrived\n", tau(c), cust[1])
    put!(input, cust[1])
end

Random.seed!(123)  # set random number seed
const μ = 1/3       # service rate
const λ = 0.9       # arrival rate
count = [0]         # a job counter

clock = Clock()   # create a clock
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
for i in 1:3      # start three server processes
    process!(clock, Prc(i, serve, i, input, output, Exponential(1/μ)))
end
# create a repeating event for 10 arrivals
event!(clock, fun(arrive, clock, input, count), every, Exponential(1/λ), n=10)
run!(clock, 20)   # run the clock
```

If we source this program, it runs a simulation.

<details><summary>output:</summary>
<pre><code>
julia> include("examples/intro.jl")
 0.141: customer 1 arrived
 0.141: server 1 serving customer 1
 1.668: server 1 finished serving 1
 2.316: customer 2 arrived
 2.316: server 2 serving customer 2
 3.154: customer 3 arrived
 3.154: server 3 serving customer 3
 4.182: customer 4 arrived
 4.182: server 1 serving customer 4
 4.364: server 3 finished serving 3
 4.409: customer 5 arrived
 4.409: server 3 serving customer 5
 4.533: customer 6 arrived
 4.566: server 2 finished serving 2
 4.566: server 2 serving customer 6
 5.072: customer 7 arrived
 5.299: server 3 finished serving 5
 5.299: server 3 serving customer 7
 5.335: server 1 finished serving 4
 5.376: customer 8 arrived
 5.376: server 1 serving customer 8
 5.833: customer 9 arrived
 6.134: customer 10 arrived
 6.570: server 1 finished serving 8
 6.570: server 1 serving customer 9
 6.841: server 3 finished serving 7
 6.841: server 3 serving customer 10
 8.371: server 2 finished serving 6
10.453: server 1 finished serving 9
10.477: server 3 finished serving 10
"run! finished with 40 clock events, 0 sample steps, simulation time: 20.0"
</code></pre>
</details>

For further examples see the [documentation](https://pbayer.github.io/DiscreteEvents.jl/dev),  or the companion site [DiscreteEventsCompanion](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/).

## Installation

`DiscreteEvents` is installed with:

```julia
pkg> add DiscreteEvents
```

The development version can be installed with:

```julia
pkg> add https://github.com/pbayer/DiscreteEvents.jl
```

Please use, test and help to develop `DiscreteEvents`! 😄

**Author:** Paul Bayer,\
**License:** MIT

<b id="f1">1</b> &nbsp; `DiscreteEvents.jl` as of `v0.3` has been renamed from [`Simulate.jl`](https://github.com/pbayer/Simulate.jl/tree/v0.2.0), see [issue #13](https://github.com/pbayer/DiscreteEvents.jl/issues/13).[↩](#a1)