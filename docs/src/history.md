# Version history

```@meta
CurrentModule = DiscreteEvents
```
## v0.3.1
A few days after the release of v0.3.0 Hector Perez contributed some macros to make the `DiscreteEvents` API more Julian for common cases:

- [`@event`](@ref): wraps [`fun`](@ref) and [`event!`](@ref) into one call,
- [`@periodic`](@ref): wraps [`fun`](@ref) and [`periodic!`](@ref) into one call,
- [`@process`](@ref): wraps [`Prc`](@ref) and [`process!`](@ref) into one call,
- [`@wait`](@ref): simplified call of [`wait!`](@ref),

The following macros provide syntactic sugar to existing functions:

- [`@delay`](@ref): calls [`delay!`](@ref),
- [`@run!`](@ref): calls [`run!`](@ref).

## v0.3.0

(2020-09-11) v0.3.0 was a significant improvement over 0.2.0 with a name change, multi-threading, resource handling and a streamlined documentation ([announcement on Julia discourse](https://discourse.julialang.org/t/ann-discreteevents-0-3/46477)).

### Breaking Name Changes

- following the [advice on discourse](https://discourse.julialang.org/t/simulate-v0-2-0-a-julia-package-for-discrete-event-simulation/31822) and in
  [issue #13](https://github.com/pbayer/DiscreteEvents.jl/issues/13) `Simulate.jl` was renamed to `DiscreteEvents.jl`. Github maintains and forwards the links.
- there are further renamings to make the API more consistent:
  - `Simfunction` → [`fun`](@ref), `SF` is no longer defined,
  - `SimProcess` → [`Prc`](@ref), `SP` is no longer defined,
  - `SimEvent` → [`DiscreteEvent`](@ref),
  - `SimCond` → [`DiscreteCond`](@ref),
  - `sample!` → [`periodic!`](@ref), was a name collision with `Distributions.jl`.
  - `reset!` → [`resetClock!`](@ref), was a name collision with `DataStructures.jl`

### Streamlined Documentation

- the documentation has been reduced to minimal introductory examples and API documentation,
- everything else (explanations, further examples, notebooks, benchmarks) has been moved to a companion site: [DiscreteEventsCompanion](https://github.com/pbayer/DiscreteEventsCompanion.jl).

### New Functionality in v0.3.0

- [`Action`](@ref) is introduced as synonym for `Union{Function,Expr,Tuple}`,
- thereby in addition to [`fun`](@ref), you can now schedule arbitrary function closures as events,  
- [`periodic!`](@ref) takes an `Action` as argument,
- you can pass also symbols, expressions or other `fun`s or function closures as arguments to [`fun`](@ref). They get evaluated at event time before being passed to the event function,
- [`DiscreteEvents.version`](@ref) gives now the package version,
- `DiscreteEvents.jl` is now much faster due to optimizations,
- [`onthread`](@ref) allows simulations with asynchronous tasks (processes and actors) to run much faster on threads other than 1,
- [`Resource`](@ref) provides an API for modeling limited resources,
- you can now create a real time clock [`RTClock`](@ref) and schedule events to it (experimental),
- actors can register their message channels to the `clock.channels` vector and the clock will not proceed before they are empty,
- processes and actors (asynchronous tasks) can transfer IO-operations to the clock with [`now!`](@ref) or print directly via the clock,
- `event!` and `delay!` now also accept stochastic time variables (a `Distribution`),
- there is a `n` keyword parameter for the number of repeat `event!`s,
- you can seed the thread-specific RNGs with [`pseed!`](@ref).

### Multi-Threading (Experimental)

- The data structure of [`Clock`](@ref) has been changed, it now has a field `ac` providing channels to parallel clocks,  
- [`PClock`](@ref) sets up a clock with parallel active clocks on each available thread,
- with [`pclock`](@ref) all parallel clocks can be accessed and referenced,
- [`process!`](@ref) can now start tasks on parallel threads,
- [`event!`](@ref) can now schedule events for execution on parallel threads,
- [`periodic!`](@ref) can now register sampling functions or expressions to parallel clocks,
- if setup with parallel clocks, [`Clock`](@ref) becomes the master to drive them and synchronize with them at each `Δt` time step,

### Other Breaking Changes in v0.3.0

- `τ` as an alias for [`tau`](@ref) is no longer defined.
- The macros `@tau`, `@val`, `@SF`, `@SP` are no longer defined.
- Logging functions have been removed (they were not useful enough).
- A function `f` given to [`Prc`](@ref) must now take a
  [`Clock`](@ref)-variable as its first argument.
- The first `::Clock`-argument to [`delay!`](@ref) and [`wait!`](@ref) and [`now!`](@ref) can no  longer be omitted. Since the task function has now a `Clock`-variable available (see above), it must provide it to `delay!`, `wait!` and `now`.
- [`event!`](@ref) no longer accepts a `Vector` as argument.
- `Clk` as alias of [`𝐶`](@ref) is no longer provided.
- [`event!`](@ref) now returns nothing.
- [`event!`](@ref) and [`periodic!`](@ref) now doesn't take anymore the scope as an argument. Symbols or expressions given to them or included in `fun`s are only evaluated in `Main` scope: this feature therefore can be used only by end users but not by any packages using `DiscreteEvents.jl`.

### Deprecated functionality in v0.3.0

- Evaluating expressions or symbols at global scope is much slower than using functions and gives now a one time warning. This functionality may be removed entirely in a future version. (Please write an issue if you want to keep it.)

## v0.2.0

(2019-12-03) This is the first version fully supporting three modeling schemes: events, processes and sampling.

- [`now!`](@ref) for IO-operations of processes,
- functions and macros for defining conditions,
- conditional [`wait!`](@ref),
- conditional events with [`event!(sim, ex, cond)`](@ref event!),
- most functions can be called without the first clock argument, default to [`𝐶`](@ref),
- [`event!`](@ref) takes an expression or a `SimFunction` or a tuple or an array of them,
- introduced aliases: `SF` for `SimFunction` and `SP` for `SimProcess`
- introduced process-based simulation: `SimProcess` and [`process!`](@ref) and [`delay!`](@ref),
- extensive documentation,
- more examples.

## v0.1.0

First registration 2019-11-04:

- event-/activity-/state-based simulation with `SimFunction` and `event!` based on Julia functions and expressions,
- introduced a central clock variable 𝐶,
- `Clock` state machine with `init!`, `run!`, `incr!`, `stop!`, `resume!`,
- `Logger` and logging functions,
- first documentation,
- first examples,
- CI and development setup.
