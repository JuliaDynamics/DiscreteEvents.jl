# News in v0.3.0

```@meta
CurrentModule = DiscreteEvents
```
v0.3.0 is a significant improvement over 0.2.0 with a name change,
multithreading, resource handling and a streamlined documentation.

## Breaking name changes
- following the [advice on discourse](https://discourse.julialang.org/t/simulate-v0-2-0-a-julia-package-for-discrete-event-simulation/31822) and in
  [issue #13](https://github.com/pbayer/DiscreteEvents.jl/issues/13) `Simulate.jl` was renamed to `DiscreteEvents.jl`. Github maintains and forwards the links.
- there are further renamings to make the API more consistent:
  - `Simfunction` → [`fun`](@ref), `SF` is no longer defined,
  - `SimProcess` → [`Prc`](@ref), `SP` is no longer defined,
  - `SimEvent` → [`DiscreteEvent`](@ref),
  - `SimCond` → [`DiscreteCond`](@ref),
  - `sample!` → [`periodic!`](@ref), was a name collision with `Distributions.jl`.

## Streamlined documentation
- the documentation has been reduced to minimal introductory examples and API
  documentation,
- everything else (further examples, notebooks, explanations, benchmarks) has
  been moved to a companion site: DiscreteEventsCompanion](https://github.com/pbayer/DiscreteEventsCompanion.jl).

## New functionality in v0.3.0
- [`Action`](@ref) is introduced as synonym for `Union{Function,Expr,Tuple}`,
- thereby in addition to `funs`, you can now schedule arbitrary function
  closures as events,  
- [`periodic!`](@ref) takes now an `Action` as argument,
- Arguments to [`fun`](@ref) can now be symbols, expressions or other `fun`s or
  function closures. They get evaluated at event time before being passed to the
  event function,
- [`DiscreteEvents.version`](@ref) gives now the package version,
- `DiscreteEvents.jl` is now much faster due to optimizations,
- [`onthread`](@ref) allows simulations with processes to run much faster on
  threads other than 1.

### Multithreading (still in the making)
- The data structure of [`Clock`](@ref) has been changed, it now has a field
  `ac` providing channels to parallel clocks,  
- [`PClock`](@ref) sets up a clock with parallel active clocks on each available
  thread,
- with [`pclock`](@ref) all parallel clocks can be accessed and referenced,
- [`process!`](@ref) can now start tasks on parallel threads,
- [`event!`](@ref) can now schedule events for execution on parallel threads,
- [`periodic!`](@ref) can now register sampling functions or expressions to
  parallel clocks,
- if setup with parallel clocks, [`Clock`](@ref) becomes the master to drive
  them and synchronize with them at each `Δt` timestep,

## Other breaking changes in v0.3.0
- `τ` as an alias for [`tau`](@ref) is no longer defined.
- The macros `@tau`, `@val`, `@SF`, `@SP` are no longer defined.
- Logging functions have been removed (they were not useful enough).
- A function `f` given to [`Prc`](@ref) must now take a
  [`Clock`](@ref)-variable as its first argument.
- The first `::Clock`-argument to [`delay!`](@ref) and [`wait!`](@ref) and
  [`now!`](@ref) can no  longer be omitted. Since the task function has now a
  `Clock`-variable available (see above), it must provide it to `delay!`,
  `wait!` and `now`.
- [`event!`](@ref) no longer accepts a `Vector` as argument.
- `Clk` as alias of [`𝐶`](@ref) is no longer provided.
- [`event!`](@ref) now returns nothing.
- [`event!`](@ref) and [`periodic!`](@ref) now doesn't take anymore the scope
  as an argument. Symbols or expressions given to them or included in `fun`s
  are only evaluated in `Main` scope: this feature therefore can be
  used only by end users but not by any packages using `DiscreteEvents.jl`.

## Deprecated functionality in v0.3.0
- Evaluating expressions or symbols at global scope is much slower than using
  functions and gives now a one time warning. This functionality may be
  removed entirely in a future version. (Please write an issue if you want to
  keep it.)

## Earlier releases

- [**Release notes**](history.md): A look at earlier releases.
