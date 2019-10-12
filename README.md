# Sim.jl

[![Build Status](https://travis-ci.com/pbayer/Sim.jl.svg?branch=master)](https://travis-ci.com/pbayer/Sim.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/pbayer/Sim.jl?svg=true)](https://ci.appveyor.com/project/pbayer/Sim-jl)
[![Codecov](https://codecov.io/gh/pbayer/Sim.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/Sim.jl)
[![Coveralls](https://coveralls.io/repos/github/pbayer/Sim.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/Sim.jl?branch=master)

Discrete event handling in Julia.

1. `Sim.jl` allows to call arbitrary Julia functions at given simulation times. It thus provides a virtual "arrow of time".
2. This allows to model and simulate discrete event systems with simple
functions and state machines.
3. Variables can be logged over simulation time and then accessed for
analysis or visualization.

### Simulation as Arrow of Time

`Sim.jl` provides a **clock** (`Clock()`) for a virtual simulation time  (a ℝ⁺ number line, `Float64`) which can mean some unit of time (day, hour, minute …), depending on the context. Events are sorted and dispatched in sequence at least computing precision apart.

Arbitrary Julia expressions become **events** with  <nobr>`event!(sim::Clock, ex::Expr, at::Float64)`</nobr> in order to be called later as we `step!` or `run!` through the simulation. Those expressions can create further events and thus generate whole chains of events, which are put in sequence and executed accordingly during simulation.

- `Clock(time::Number=0)`: creates a new simulation clock
- `event!(sim::Clock, expr::Expr, at::Float64)`: schedule an expression for execution at a given simulation time.
- `run!(sim::Clock, duration::Number)`: Run a simulation for a given duration. Call all scheduled events in that timeframe.
- `step!(sim::Clock)`: Take one simulation step, execute the next event.
- `now(sim::Clock)`: Return the current simulation time.
