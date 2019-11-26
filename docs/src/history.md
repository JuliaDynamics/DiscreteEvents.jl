# Version history

## v0.2.0
- [`now!`](@ref) for IO-operations of processes,
- functions and macros for defining conditions,
- conditional [`wait!(cond)`](@ref wait!),
- conditional events with [`event!(sim, ex, cond)`](@ref event!),
- most functions can be called without the first clock argument, default to [`𝐶`](@ref),
- [`event!`](@ref) takes an expression or a [`SimFunction`](@ref) or a tuple or an array of them,
- introduced aliases: [`SF`](@ref SimFunction) for [`SimFunction`](@ref) and [`SP`](@ref SimProcess) for [`SimProcess`](@ref)
- introduced process-based simulation: [`SimProcess`](@ref) and [`process!`](@ref) and [delay!](@ref),
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
