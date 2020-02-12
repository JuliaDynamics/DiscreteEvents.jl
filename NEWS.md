# Simulate v0.3.0 news (future release notes)

v0.3.0 is a significant improvement over 0.2.0 with a name change,
multithreading, resource handling and a streamlined documentation.

## breaking name changes
- following the advice on [discourse](https://discourse.julialang.org/t/simulate-v0-2-0-a-julia-package-for-discrete-event-simulation/31822) and in
  [issue #13](https://github.com/pbayer/Simulate.jl/issues/13) `Simulate.jl`  
  gets renamed to `DiscreteEvents.jl`. Github maintains and forwards the links.
- there are further renamings to make the API more consistent:
  - `Simfunction` → `fun`, `SF` is no longer defined,
  - `SimProcess` → `Prc`, `SP` is no longer defined,
  - `SimEvent` → `DiscreteEvent`,
  - `SimCond` → `DiscreteCond`,
  - `sample!` → `periodic!`, was a name collision with `Distributions.jl`.

## New functionality in v0.3.0
- `Action` is introduced as synonym for `Union{Expr,Function,Tuple}`,
- thereby in addition to `funs`, you can now schedule arbitrary function
  closures as events,  
- `periodic!` takes now an `Action` as argument,
- Arguments to `fun` can now be given also as symbols, expressions or as
  other `fun`s or function closures. They get evaluated at event time before
  being passed to the event function,
- `Simulate.version` gives now the package version,
- `Simulate.jl` is now much faster due to optimizations,

### Multithreading (still in the making)
- The data structure of `Clock` has been changed, it now has a field
  `ac` providing channels to parallel clocks,  
- `PClock` sets up a clock with parallel active clocks on each available
  thread,
- with `pclock` all parallel clocks can be accessed and referenced,
- `process!` can now start tasks on parallel threads,
- `event!` can now schedule events for execution on parallel threads,
- `periodic!` can now register sampling functions or expressions to
  parallel clocks,
- if setup with parallel clocks, `Clock` becomes the master to drive
  them and synchronize with them at each `Δt` timestep,

## Other breaking changes in v0.3.0
- `τ` as an alias for `tau` is no longer defined.
- The macros `@tau`, `@val`, `@SF`, `@SP` are no longer defined.
- Logging functions have been removed (they were not useful enough).
- A function `f` given to `Prc` must now take a
  `Clock`-variable as its first argument.
- The first `::Clock`-argument to `delay!` and `wait!` and
  `now!` can no  longer be omitted. Since the task function has now a
  `Clock`-variable available (see above), it must provide it to `delay!`,
  `wait!` and `now`.
- `event!` no longer accepts a `Vector` as argument.
- `Clk` as alias of `𝐶` is no longer provided.
- `event!` now returns nothing.
- `event!` and `periodic!` now doesn't take anymore the scope
  as an argument. Symbols or expressions given to them or included in `fun`s
  are only evaluated in `Main` scope: this feature therefore can be
  used only by end users but not by any packages using `Simulate.jl`.

## Deprecated functionality in v0.3.0
- Evaluating expressions or symbols at global scope is much slower than using
  functions and gives now a one time warning. This functionality may be
  removed entirely in a future version. (Please write an issue if you want to
  keep it.)
