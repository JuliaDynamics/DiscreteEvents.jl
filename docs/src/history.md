# Version history

## v0.2.0 (development)
- introduced process-based simulation with `SimProcess` and `process!`,
- **planned**: conditional events with `event!(sim, ex, cond)` and `wait!(cond)` where `cond::Union{Expr, SimFunction}`,
- **planned**: SimFunction takes also a tuple of functions.
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
