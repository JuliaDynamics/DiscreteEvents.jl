# Sim.jl

[![Build Status](https://travis-ci.com/pbayer/Sim.jl.svg?branch=master)](https://travis-ci.com/pbayer/Sim.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/pbayer/Sim.jl?svg=true)](https://ci.appveyor.com/project/pbayer/Sim-jl)
[![Codecov](https://codecov.io/gh/pbayer/Sim.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/Sim.jl)
[![Coveralls](https://coveralls.io/repos/github/pbayer/Sim.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/Sim.jl?branch=master)

Discrete event simulaition in Julia:

1. `Sim.jl` evaluates Julia functions at given (virtual) simulation times.
2. Thus discrete event systems based on state machines can be modeled and simulated.
3. Variables can be logged over simulation time and then accessed for
analysis or visualization.

`Sim.jl` provides a **clock** for a virtual simulation time  (a `Float64`) with an arbitrary unit of time. **Events** are dispatched in sequence on this time line at least computing precision apart.

A Julia expression can be scheduled as `event` to be evaluated later as we `step` or `run` through the simulation. It can then create further events and thus generate whole chains of events, which are put in sequence and executed  during simulation.

- `Clock(time::Number=0)`: creates a new simulation clock
- `event!(sim::Clock, expr::Expr, at::Float64)`: schedule an expression for execution at a given simulation time.
- `run!(sim::Clock, duration::Number)`: Run a simulation for a given duration. Call all scheduled events in that timeframe.
- `step!(sim::Clock)`: Take one simulation step, execute the next event.
- `now(sim::Clock)`: Return the current simulation time.
