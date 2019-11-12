# Version history

## v0.2.0 (development)
- **next**: conditional events with `event!(sim, ex, cond)` and `wait!(cond)` where `cond::Union{SimExpr, Array{SimExpr,1}}`,
- `event!` can be called without the first clock argument, it then goes to `𝐶`.
- `event!` takes an expression or a SimFunction or a tuple or an array of them,
- introduced aliases: `𝐅` for `SimFunction` and `𝐏` for `SimProcess`
- introduced process-based simulation with `SimProcess` and `process!`,
- extensive documentation
- more examples

## v0.1.0

- first registration 2019-11-04
- event-/activity-/state-based simulation with `SimFunction` and `event!` based on Julia functions and expressions.
- introduced a central clock variable 𝐶
- `Clock` state machine with `init!`, `run!`, `incr!`, `stop!`, `resume!`
- `Logger` and logging functions
- first documentation
- first examples
- CI and development setup
