# Sim.jl

[![Build Status](https://travis-ci.com/pbayer/Sim.jl.svg?branch=master)](https://travis-ci.com/pbayer/Sim.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/pbayer/Sim.jl?svg=true)](https://ci.appveyor.com/project/pbayer/Sim-jl)
[![Codecov](https://codecov.io/gh/pbayer/Sim.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/Sim.jl)
[![Coveralls](https://coveralls.io/repos/github/pbayer/Sim.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/Sim.jl?branch=master)

Discrete event simulation in Julia:

1. `Sim.jl` evaluates Julia functions at given (virtual) simulation times.
2. Thus discrete event systems based on state machines can be modeled and simulated.
3. Variables can be logged over simulation time and then accessed for
analysis or visualization.

`Sim.jl` provides a **clock** for a virtual simulation time  (a `Float64`) with an arbitrary unit of time. **Events** are scheduled and dispatched in sequence on this time line.

A Julia expression is scheduled as `event` and evaluated as we `step` or `run` through the simulation. It can at runtime create further events or chains of events to be scheduled and called during simulation.

- `Clock(time::Number=0)`: create a new virtual clock
- `event!(sim::Clock, expr::Expr, t::Float64)` or <nobr>`event!(sim, expr, at, t)`</nobr> or <nobr>`event!(sim, expr, after, t)`</nobr>: schedule an expression for evaluation at a given simulation time.
- `run!(sim::Clock, duration::Number)`: Run a simulation for a given duration. Call all scheduled events in that timeframe.
- `step!(sim::Clock)`: Take one simulation step, execute the next event.
- `now(sim::Clock)`: Return the current simulation time.

## Traffic light example

A traffic light has three alternating lights: red, orange, green. If it has a failure, the red lamp blinks.
