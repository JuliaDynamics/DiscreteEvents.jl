# Simulate.jl

A Julia package for discrete event simulation.

`Simulate.jl` provides *three schemes* for modeling and simulating discrete event systems (DES): 1) [event scheduling](@ref event_scheme), 2) [interacting processes](@ref process_scheme) and 3) [continuous sampling](@ref continuous_sampling). It introduces a *clock* and allows to schedule arbitrary  functions or expressions as *events*, *processes* or *sampling* operations on the clock's timeline. It provides simplicity and flexibility in building models and performance in simulation.

!!! warning "Development documentation"
    The development documentation is not yet updated. Many **examples**
    do not reflect the latest changes in the API and run only on v0.2.0!
    See the [news for a list of changes](news.md) in the API.

## Overview

- [**Getting started**](intro.md): Get an overview and learn the basics.
- [**Usage**](usage.md): Get detailed informations about types, functions and macros in `Simulate.jl`.
- [**Troubleshooting**](troubleshooting.md): If something doesn't work as expected.

## Companion

- There is a companion site [DiscreteEventsCompanion](https://github.com/pbayer/DiscreteEventsCompanion.jl) with notebooks, further docs, examples and benchmarks.

## Development

`Simulate.jl` is a new package and still in active development. Please use, test and help  evolve it. Its GitHub repository is at [https://github.com/pbayer/Simulate.jl](https://github.com/pbayer/Simulate.jl).

**Author:** Paul Bayer
**License:** MIT
