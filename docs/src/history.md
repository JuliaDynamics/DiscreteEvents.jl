# Version history

## v0.2.0

This is the first version fully supporting three modeling schemes: events, processes and sampling.

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

- first registration 2019-11-04
- event-/activity-/state-based simulation with `SimFunction` and `event!` based on Julia functions and expressions,
- introduced a central clock variable 𝐶,
- `Clock` state machine with `init!`, `run!`, `incr!`, `stop!`, `resume!`,
- `Logger` and logging functions,
- first documentation,
- first examples,
- CI and development setup.
