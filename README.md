# Sim.jl

[![Build Status](https://travis-ci.com/pbayer/Sim.jl.svg?branch=master)](https://travis-ci.com/pbayer/Sim.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/pbayer/Sim.jl?svg=true)](https://ci.appveyor.com/project/pbayer/Sim-jl)
[![Codecov](https://codecov.io/gh/pbayer/Sim.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/Sim.jl)
[![Coverage Status](https://coveralls.io/repos/github/pbayer/Sim.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/Sim.jl?branch=master)

## Discrete event simulation in Julia:

1. `Sim.jl` evaluates Julia expressions at given (virtual) simulation times.
2. Thus discrete event systems based on state machines can be modeled and simulated.
3. Variables can be logged over simulation time and then accessed for
analysis or visualization.

### The clock

`Sim.jl` provides a clock for a simulation time  (a `Float64`) with an arbitrary unit of time.

- `Clock(Δt::Number=0; t0::Number=0)`: create a new clock with start time `t0` and sample time `Δt`.
- `now(sim::Clock)`: Return the current simulation time.
- `sample_time!(sim::Clock, Δt::Number)`: set the clock's sample rate starting from `now(sim)`.

If no Δt is given, the simulation doesn't tick with a fixed interval, but jumps from event to event.

### Expressions as Events

Julia expressions are scheduled as events on the clock's time line:

- `event!(sim::Clock, expr::Expr, t::Float64)` or
- `event!(sim, expr, at, t)`: schedule an expression for evaluation at a given simulation time.
- `event!(sim, expr, after, t):` schedule an expression for evaluation `t` after current simulation time.
- `event!(sim, expr, every, Δt)`: schedule an expression for evaluation now and at every time step `Δt` until end of simulation.

Events are evaluated later as we `step` or `run` through the simulation. They may then at runtime create further events and thus cause chains of events to be scheduled and called during simulation.

### Sampling expressions

If we provided the clock with a time interval `Δt`, the clock ticks with a fixed sample rate. At each tick it will evaluate expressions, we give it with:

- `sample!(sim::Clock, expr::Expr)`: enqueue an expression for sampling.

Sampling expressions are evaluated at clock ticks in the sequence they were registered with `sample!`. They are evaluated before any events which may have been scheduled for the same time.

### Running the simulation

Now, after we have setup a clock, scheduled expressions as events or registered them for sampling, we can step or run through a simulation, stop or resume it.

- `run!(sim::Clock, duration::Number)`: Run a simulation for a given duration. Call and evaluate all ticks and scheduled events in that timeframe.
- `step!(sim::Clock)`: Take one simulation step, execute the next tick or event.
- `stop!(sim::Clock)`: Stop a simulation
- `resume!(sim::Clock)`: Resume a halted simulation.

## Traffic light example

A traffic light has three alternating lights: red, orange, green. If it fails, the red lamp blinks.
