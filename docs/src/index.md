# Simulate.jl

A Julia package for discrete event simulation.

`Simulate.jl` supports different approaches to modeling and simulation of discrete event systems (DES). It provides three major schemes: 1) an [event-scheduling scheme](@ref event_scheme), 2) a [process-oriented scheme](@ref process_scheme) and 3) [continuous sampling](@ref continuous_sampling). With them [different modeling strategies](approach.md) can be applied.

## Overview

- [**Getting started**](intro.md): Get an overview and learn the basics.
- [**Building models**](approach.md): Use and combine different approaches to modeling and simulation.
- [**Usage**](usage.md): Get detailed informations about types, functions and macros.
- [**Examples**](examples/examples.md): Look at and learn from examples.
- [**Internals**](internals.md): Get informations about internal functions.
- [**Troubleshooting**](troubleshooting.md): If something doesn't work as expected.
- [**Release notes**](history.md): A look at earlier releases.

## New in dev v0.2.0

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

**Author:** Paul Bayer
**License:** MIT
