## Discrete event simulation in Julia:

1. [`Sim.jl`](https://github.com/pbayer/Sim.jl) evaluates Julia expressions at given (virtual) simulation times.
2. Thus discrete event systems based on state machines can be modeled and simulated.
3. Variables can be logged over simulation time and then accessed for
analysis or visualization.

### The clock

`Sim.jl` provides a clock for a simulation time  (a `Float64`) with an arbitrary unit of time.

- `Clock(Δt::Number=0; t0::Number=0)`: create a new clock with start time `t0` and sample time `Δt`.
- `now(sim::Clock)`: return the current simulation time.
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

If we provide the clock with a time interval `Δt`, the clock ticks with a fixed sample rate. At each tick it will evaluate expressions, we register with:

- `sample!(sim::Clock, expr::Expr)`: enqueue an expression for sampling.

Sampling expressions are evaluated at clock ticks in the sequence they were registered. They are evaluated before any events which may have been scheduled for the same time.

### Running the simulation

Now, after we have setup a clock, scheduled expressions as events or registered them for sampling, we can step or run through a simulation, stop or resume it.

- `run!(sim::Clock, duration::Number)`: run a simulation for a given duration. Call and evaluate all ticks and scheduled events in that timeframe.
- `step!(sim::Clock)`: take one simulation step, execute the next tick or event.
- `stop!(sim::Clock)`: stop a simulation
- `resume!(sim::Clock)`: resume a halted simulation.

Now we can evaluate the results.

### Logging

Logging enables us to trace variables over simulation time and such analyze their behaviour.

- `L = Logger()`: create a new logger, providing the newest record `L.last`, a logging table `L.df` and a switch `L.ltype` between logging types.
- `init!(L::Logger, sim::Clock)`:
- `setup!(L::Logger, vars::Array{Symbol})`: setup `L`, providing it with an array of logging variables `[:a, :b, :c ...]`
- `switch!(L::Logger, to::Number=0)`: switch between `0`: only keep the last record, `1`: print, `2`: write records to the table
- `record!(L::Logger)`: record the logging variables with current simulation time.
