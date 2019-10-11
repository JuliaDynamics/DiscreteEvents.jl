# Sim.jl

[![Build Status](https://travis-ci.com/pbayer/Sim.jl.svg?branch=master)](https://travis-ci.com/pbayer/Sim.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/pbayer/Sim.jl?svg=true)](https://ci.appveyor.com/project/pbayer/Sim-jl)
[![Codecov](https://codecov.io/gh/pbayer/Sim.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/Sim.jl)
[![Coveralls](https://coveralls.io/repos/github/pbayer/Sim.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/Sim.jl?branch=master)

Discrete event handling in Julia.

1. `Sim.jl` allows to call arbitrary Julia functions at given simulation times. It thus provides a virtual "arrow of time".
2. This allows **state machines** thus as those in `StateMachines.jl`
to model and simulate discrete event systems
3. States and transitions over simulation time can be logged and
thus printed, analyzed or visualized.

### Simulation as Arrow of Time

We introduce a **clock** (`Clock()`) containing the simulation time, to which simulation **events** (`SimEvent`) can refer. The simulation time is implemented as a ℝ⁺ number line (`Float64`) and can mean some unit of time (day, hour, minute …), depending on the context. We assume that there are no really simultaneous events. So events are sorted and dispatched in timely sequence at least computing precision apart.

We schedule arbitrary Julia expressions as events with  <nobr>`event!(sim::Clock, ex::Expr, at::Float64)`</nobr> in order to be called later as we `step!` or `run!` through the simulation. If those expressions create further events, whole chains of events are generated, put in sequence and executed accordingly during simulation.

- `Clock(time::Number=0)`: creates a new simulation clock
- `event!(sim::Clock, expr::Expr, at::Float64)`: schedule an expression for execution at a given simulation time.
- `run!(sim::Clock, duration::Number)`: Run a simulation for a given duration. Call all scheduled events in that timeframe.
- `step!(sim::Clock)`: Take one simulation step, execute the next event.
- `now(sim::Clock)`: Return the current simulation time.
