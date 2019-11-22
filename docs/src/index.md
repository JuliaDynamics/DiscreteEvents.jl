# Simulate.jl

A Julia package for discrete event simulation.

`Simulate.jl` extends the [Julia language](https://julialang.org) with *three major schemes* for modeling and simulation of discrete event systems (DES): 1) [event scheduling](@ref event_scheme), 2) [processes](@ref process_scheme) and 3) [continuous sampling](@ref continuous_sampling). With them [different modeling strategies](approach.md) can be realized.

## Overview

- [**Getting started**](intro.md): Get an overview and learn the basics.
- [**Building models**](approach.md): Use and combine different approaches to modeling and simulation.
- [**Usage**](usage.md): Get detailed informations about types, functions and macros in `Simulate.jl`.
- [**Examples**](examples/examples.md): Look at and learn from examples.
- [**Internals**](internals.md): Get informations about internal functions.
- [**Troubleshooting**](troubleshooting.md): If something doesn't work as expected.

## Development

`Simulate.jl` is a new package and still in early development. Please use and test it and help it evolve. Its GitHub repository is at https://github.com/pbayer/Simulate.jl.

### New in dev v0.2.0

v0.2.0 aims to be the first version supporting fully the three major schemes. It does not yet contain a library for DES entities like sources, queues, servers ... but – as the examples show – those can be realized with functions in the Julia library and packages like [`DataStructures.jl`](https://github.com/JuliaCollections/DataStructures.jl).

- [`now!`](@ref) for IO-operations of processes,
- functions and macros for defining conditions,
- conditional [`wait!(cond)`](@ref wait!),
- conditional events with [`event!(sim, ex, cond)`](@ref event!),
- everything can be called without the first clock argument, it then goes to [`𝐶`](@ref),
- [`event!`](@ref) takes an expression or a [`SimFunction`](@ref) or a tuple or an array of them,
- introduced aliases: [`SF`](@ref SimFunction) for [`SimFunction`](@ref) and [`SP`](@ref SimProcess) for [`SimProcess`](@ref)
- introduced process-based simulation: [`SimProcess`](@ref) and [`process!`](@ref) and [`delay!`](@ref),
- extensive documentation,
- more examples,

### Earlier releases

- [**Release notes**](history.md): A look at earlier releases.

**Author:** Paul Bayer
**License:** MIT
