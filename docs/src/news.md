# News in v0.3.0

v0.3.0 is a significant improvement over 0.2.0 with a name change, 
multithreading, resource handling and a streamlined documentation.

## Name change
- following the [advice on discourse](https://discourse.julialang.org/t/simulate-v0-2-0-a-julia-package-for-discrete-event-simulation/31822) and in
  [issue #13](https://github.com/pbayer/Simulate.jl/issues/13) `Simulate.jl`  
  gets renamed to `DiscreteEvents.jl`. Github maintains and forwards the links.

## Breaking changes in v0.3.0
- name change, see above,
- Logging functions are now removed (they were not useful enough),
- A function `func` given to [`SimFunction`](@ref) must now take a
  [`Clock`](@ref)-variable as its first argument,
- The first `::Clock`-argument to [`delay!`](@ref) and [`wait!`](@ref) can no
  longer be omitted. Since the task function has now a `Clock`-variable
  available (see above), it must call `delay!` and `wait!` with that.

## New functionality in v0.3.0
- Arguments to `SimFunction` can now be given also as symbols, expressions or as
  other SimFunctions. They get evaluated at event time before being
  passed to the event function,
- [`Simulate.version`](@ref) gives now the package version,
- `Simulate.jl` is now faster due to optimizations,
- The data structure of [`Clock`](@ref) has been changed, it now has a field
  `ac` providing channels to parallel clocks,  
- [`PClock`](@ref) sets up a clock with parallel clocks on each available
  thread.
- [`process!`](@ref) can now `spawn` tasks to parallel threads,
- if setup with parallel clocks, [`Clock`](@ref) now drives them and
  synchronizes at each `Δt` timestep with them,

## Deprecated functionality in v0.3.0
- Evaluating expressions or symbols at global scope is much slower than using
  `SimFunction`s and gives now a one time warning. This functionality may be
  removed entirely in a future version. (Please write an issue if you want to
  keep it.)

## Earlier releases

- [**Release notes**](manual/history.md): A look at earlier releases.
