# Simulate.jl

A Julia package for discrete event simulation.

`Simulate.jl` provides *three schemes* for modeling and simulating discrete event systems (DES): 1) [event scheduling](@ref event_scheme), 2) [interacting processes](@ref process_scheme) and 3) [continuous sampling](@ref continuous_sampling). By building directly on [Julia](https://julialang.org) it aims for [simplicity](intro.md) and [flexibility](approach.md) in building models and for high performance in simulation.

## Overview

- [**Getting started**](intro.md): Get an overview and learn the basics.
- [**Building models**](approach.md): Use and combine different approaches to modeling and simulation.
- [**Usage**](usage.md): Get detailed informations about types, functions and macros in `Simulate.jl`.
- [**Examples**](examples/examples.md): Look at and learn from examples.
- [**Internals**](internals.md): Get informations about internal functions.
- [**Troubleshooting**](troubleshooting.md): If something doesn't work as expected.

## Development

`Simulate.jl` is a new package and still in early development. Please use and test it and help it evolve. Its GitHub repository is at [https://github.com/pbayer/Simulate.jl](https://github.com/pbayer/Simulate.jl).

### New in v0.2.0

v0.2.0 is the first version supporting fully the three schemes.

- [`now!`](@ref) for IO-operations of processes,
- functions and macros for defining conditions,
- conditional [`wait!(cond)`](@ref wait!),
- conditional events with [`event!(sim, ex, cond)`](@ref event!),
- most functions can be called without the first clock argument, default to [`𝐶`](@ref),
- [`event!`](@ref) takes an expression or a [`SimFunction`](@ref) or a tuple or an array of them,
- introduced aliases: [`SF`](@ref SimFunction) for [`SimFunction`](@ref) and [`SP`](@ref SimProcess) for [`SimProcess`](@ref)
- introduced process-based simulation: [`SimProcess`](@ref) and [`process!`](@ref) and [`delay!`](@ref),
- extensive documentation,
- more examples.

### Earlier releases

- [**Release notes**](history.md): A look at earlier releases.

**Author:** Paul Bayer
**License:** MIT
