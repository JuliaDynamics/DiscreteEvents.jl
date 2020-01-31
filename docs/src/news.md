# News in v0.3.0

```@meta
CurrentModule = Simulate
```
v0.3.0 is a significant improvement over 0.2.0 with a name change,
multithreading, resource handling and a streamlined documentation.

## breaking name changes
- following the [advice on discourse](https://discourse.julialang.org/t/simulate-v0-2-0-a-julia-package-for-discrete-event-simulation/31822) and in
  [issue #13](https://github.com/pbayer/Simulate.jl/issues/13) `Simulate.jl`  
  gets renamed to `DiscreteEvents.jl`. Github maintains and forwards the links.
- there are further renamings to make the API more consistent:
  - `Simfunction` → [`Fun`](@ref), `SF` is no longer defined,
  - `SimProcess` → [`Prc`](@ref), `SP` is no longer defined,
  - `SimEvent` → [`DiscreteEvent`](@ref),
  - `SimCond` → [`DiscreteCond`](@ref),  

## New functionality in v0.3.0
- [`Action`](@ref) is introduced as synonym for `Union{Expr,Fun,Tuple}`,
- Arguments to [`Fun`](@ref) can now be given also as symbols, expressions or as
  other `Fun`s. They get evaluated at event time before being
  passed to the event function,
- [`Simulate.version`](@ref) gives now the package version,
- `Simulate.jl` is now much faster due to optimizations,

### Multithreading (still in the making)
- The data structure of [`Clock`](@ref) has been changed, it now has a field
  `ac` providing channels to parallel clocks,  
- [`PClock`](@ref) sets up a clock with parallel active clocks on each available
  thread,
- with [`pclock`](@ref) all parallel clocks can be accessed and referenced,
- [`process!`](@ref) can now start tasks on parallel threads,
- [`event!`](@ref) can now schedule events for execution on parallel threads,
- [`sample!`](@ref) can now register sampling functions or expressions to
  parallel clocks,
- if setup with parallel clocks, [`Clock`](@ref) becomes the master to drive
  them and synchronize with them at each `Δt` timestep,

## Breaking changes in v0.3.0
- `τ` as an alias for [`tau`](@ref) is no longer defined,
- the macros `@tau`, `@val`, `@SF`, `@SP` are no longer defined
- Logging functions have been removed (they were not useful enough),
- A function `f` given to [`Prc`](@ref) must now take a
  [`Clock`](@ref)-variable as its first argument,
- The first `::Clock`-argument to [`delay!`](@ref) and [`wait!`](@ref) and
  [`now!`](@ref) can no  longer be omitted. Since the task function has now a
  `Clock`-variable available (see above), it must provide it to `delay!`,
  `wait!` and `now`.
- [`event!`](@ref) no longer accepts a `Vector` as argument.

## Deprecated functionality in v0.3.0
- Evaluating expressions or symbols at global scope is much slower than using
  `SimFunction`s and gives now a one time warning. This functionality may be
  removed entirely in a future version. (Please write an issue if you want to
  keep it.)

## Earlier releases

- [**Release notes**](manual/history.md): A look at earlier releases.
