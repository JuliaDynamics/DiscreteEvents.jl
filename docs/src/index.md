# Simulate.jl

A Julia package for discrete event simulation.

`Simulate.jl` provides *three schemes* for modeling and simulating discrete event systems (DES): 1) [event scheduling](@ref event_scheme), 2) [interacting processes](@ref process_scheme) and 3) [continuous sampling](@ref continuous_sampling). It introduces a *clock* and allows to schedule arbitrary Julia functions or expressions as *events*, *processes* or *sampling* operations on the clock's timeline. Thus it provides [simplicity](intro.md) and [flexibility](approach.md) in building models and performance in simulation.

## Overview

- [**Getting started**](intro.md): Get an overview and learn the basics.
- [**Building models**](approach.md): Use and combine different approaches to modeling and simulation.
- [**Usage**](usage.md): Get detailed informations about types, functions and macros in `Simulate.jl`.
- [**Examples**](examples/examples.md): Look at and learn from examples.
- [**Internals**](internals.md): Get informations about internal functions.
- [**Performance**](performance.md): How to get good performance for your simulations.
- [**Troubleshooting**](troubleshooting.md): If something doesn't work as expected.

## Development

`Simulate.jl` is a new package and still in early development. Please use, test and help  evolve it. Its GitHub repository is at [https://github.com/pbayer/Simulate.jl](https://github.com/pbayer/Simulate.jl).

### Breaking changes in v0.3.0
- **breaking change**: Logging functions are now removed (they were not useful
  enough).

### New functionality in v0.3.0
- Arguments to `SimFunction` can now be given also as symbols, expressions or as
  other SimFunctions. They will then be evaluated at event time before they are
  passed to the event function.
  - `Simulate.version` gives now the package version.
  - `Simulate.jl` is now faster due to optimizations.

### Deprecated functionality in v0.3.0
- Evaluating expressions or symbols at global scope is much slower than using
  `SimFunction`s and gives now a one time warning. This functionality may be
  removed entirely in a future version. (Please write an issue if you want to
  keep it.)

### Earlier releases

- [**Release notes**](history.md): A look at earlier releases.

**Author:** Paul Bayer
**License:** MIT
