# DiscreteEvents news 

## v0.3.1

(released 2020-09-16) A few days after the release of v0.3.0 Hector Perez contributed some macros to make the `DiscreteEvents` API more Julian for common cases:

- `@event`: wraps `fun` and `event!` into one call,
- `@periodic`: wraps `fun` and `periodic!` into one call,
- `@process`: wraps `Prc` and `process!` into one call,
- `@wait`: simplified call of `wait!`,

The following macros provide syntactic sugar to existing functions:

- `@delay`: calls `delay!`,
- `@run!`: calls `run!`.

## v0.3.0

(released 2020-09-11) v0.3.0 was a significant improvement over 0.2.0 with a name change, multi-threading, resource handling and a streamlined documentation ([announcement on Julia discourse](https://discourse.julialang.org/t/ann-discreteevents-0-3/46477)).

### Breaking Name Changes

- following the [advice on discourse](https://discourse.julialang.org/t/simulate-v0-2-0-a-julia-package-for-discrete-event-simulation/31822) and in
  [issue #13](https://github.com/pbayer/DiscreteEvents.jl/issues/13) `Simulate.jl` was renamed to `DiscreteEvents.jl`. Github maintains and forwards the links.
- there are further renamings to make the API more consistent:
  - `Simfunction` → `fun`, `SF` is no longer defined,
  - `SimProcess` → `Prc`, `SP` is no longer defined,
  - `SimEvent` → `DiscreteEvent`,
  - `SimCond` → `DiscreteCond`,
  - `sample!` → `periodic!`, was a name collision with `Distributions.jl`.
  - `reset!` → `resetClock!`, was a name collision with `DataStructures.jl`

### Streamlined Documentation

- the documentation has been reduced to minimal introductory examples and API documentation,
- everything else (explanations, further examples, notebooks, benchmarks) has been moved to a companion site: [DiscreteEventsCompanion](https://github.com/pbayer/DiscreteEventsCompanion.jl).

### New Functionality in v0.3.0

- `Action` is introduced as synonym for `Union{Function,Expr,Tuple}`,
- thereby in addition to `fun`, you can now schedule arbitrary function closures as events,  
- `periodic!` takes an `Action` as argument,
- you can pass also symbols, expressions or other `fun`s or function closures as arguments to `fun`. They get evaluated at event time before being passed to the event function,
- `DiscreteEvents.version` gives now the package version,
- `DiscreteEvents.jl` is now much faster due to optimizations,
- `onthread` allows simulations with asynchronous tasks (processes and actors) to run much faster on threads other than 1,
- `Resource` provides an API for modeling limited resources,
- you can now create a real time clock `RTClock` and schedule events to it (experimental),
- actors can register their message channels to the `clock.channels` vector and the clock will not proceed before they are empty,
- processes and actors (asynchronous tasks) can transfer IO-operations to the clock with `now!` or print directly via the clock,
- `event!` and `delay!` now also accept stochastic time variables (a `Distribution`),
- there is a `n` keyword parameter for the number of repeat `event!`s,
- you can seed the thread-specific RNGs with `pseed!`.

### Multi-Threading (Experimental)

- The data structure of `Clock` has been changed, it now has a field `ac` providing channels to parallel clocks,  
- `PClock` sets up a clock with parallel active clocks on each available thread,
- with `pclock` all parallel clocks can be accessed and referenced,
- `process!` can now start tasks on parallel threads,
- `event!` can now schedule events for execution on parallel threads,
- `periodic!` can now register sampling functions or expressions to parallel clocks,
- if setup with parallel clocks, `Clock` becomes the master to drive them and synchronize with them at each `Δt` time step,

### Other Breaking Changes in v0.3.0

- `τ` as an alias for `tau` is no longer defined.
- The macros `@tau`, `@val`, `@SF`, `@SP` are no longer defined.
- Logging functions have been removed (they were not useful enough).
- A function `f` given to `Prc` must now take a
  `Clock`-variable as its first argument.
- The first `::Clock`-argument to `delay!` and `wait!` and `now!` can no  longer be omitted. Since the task function has now a `Clock`-variable available (see above), it must provide it to `delay!`, `wait!` and `now`.
- `event!` no longer accepts a `Vector` as argument.
- `Clk` as alias of `𝐶` is no longer provided.
- `event!` now returns nothing.
- `event!` and `periodic!` now doesn't take anymore the scope as an argument. Symbols or expressions given to them or included in `fun`s are only evaluated in `Main` scope: this feature therefore can be used only by end users but not by any packages using `DiscreteEvents.jl`.

### Deprecated functionality in v0.3.0

- Evaluating expressions or symbols at global scope is much slower than using functions and gives now a one time warning. This functionality may be removed entirely in a future version. (Please write an issue if you want to keep it.)
