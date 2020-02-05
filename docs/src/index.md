# Simulate.jl

A Julia package for discrete event simulation.

`Simulate.jl` provides *three schemes* for modeling and simulating discrete event systems (DES): 1) [event scheduling](@ref event_scheme), 2) [interacting processes](@ref process_scheme) and 3) [continuous sampling](@ref continuous_sampling). It introduces a *clock* and allows to schedule arbitrary Julia functions or expressions as *events*, *processes* or *sampling* operations on the clock's timeline. It provides [simplicity](manual/intro.md) and [flexibility](manual/approach.md) in building models and performance in simulation.

!!! warning "Development documentation"
    The development documentation is not yet updated. Many **examples**
    do not reflect the latest changes in the API and run only on v0.2.0!
    See the [news for a list of changes](news.md) in the API.

## Overview

- [**Getting started**](manual/intro.md): Get an overview and learn the basics.
- [**Building models**](manual/approach.md): Use and combine different approaches to modeling and simulation.
- [**Parallel simulation**](manual/parallel.md): If you want to parallelize your simulations.
- [**Real time events**](manual/timer.md): setup real time clocks and schedule events to them.
- [**Usage**](manual/usage.md): Get detailed informations about types, functions and macros in `Simulate.jl`.
- [**Performance**](performance/performance.md): How to get good performance for your simulations.
- [**Examples**](examples/examples.md): Look at and learn from examples.
- [**Internals**](manual/internals.md): Get informations about internal functions.
- [**Troubleshooting**](manual/troubleshooting.md): If something doesn't work as expected.

## Development

`Simulate.jl` is a new package and still in active development. Please use, test and help  evolve it. Its GitHub repository is at [https://github.com/pbayer/Simulate.jl](https://github.com/pbayer/Simulate.jl).

**Author:** Paul Bayer
**License:** MIT
