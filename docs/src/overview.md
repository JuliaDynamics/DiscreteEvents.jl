### Discrete event simulation with `Sim.jl`

1. [`Sim.jl`](https://github.com/pbayer/Sim.jl) evaluates Julia expressions or arbitrary functions at given (virtual) simulation times.
2. Thus discrete event systems based on state machines can be modeled and simulated.
3. Variables can be logged over simulation time and then accessed for
analysis or visualization.

### The clock

`Sim.jl` provides a clock for a simulation time  (a `Float64`) with an arbitrary unit of time.

- `Clock(Δt::Number=0; t0::Number=0)`: create a new clock with start time `t0` and sample time `Δt`.
- `Τ` or `Tau` : is the central Clock() variable.
- `τ(sim::Clock=Τ)`: return the current clock time.
- `sample_time!(sim::Clock, Δt::Number)`: set the clock's sample rate starting from `now(sim)`.
- `reset!(sim::Clock, Δt::Number=0; t0::Time=0, hard::Bool=true)`: reset a clock.
- `sync!(sim::Clock, to::Clock=Τ)`: Force a synchronization of two clocks.

If no Δt ≠ 0 is given, the simulation doesn't tick with a fixed interval, but jumps from event to event.

### Functions and expressions as Events

Julia functions or expressions are scheduled as events on the clock's time line:

- `SimFunction(func::Function, arg...; kw...)`: prepare a function and its arguments for simulation.
- `event!(sim::Clock, ex::Union{Expr,SimFunction}, t::Float64)` or
- `event!(sim, ex, at, t)`: schedule a function or an expression for a given simulation time.
- `event!(sim, ex, after, t):` schedule a function or an expression for time `t` after current simulation time.
- `event!(sim, ex, every, Δt)`: schedule a function an expression for now and every time step `Δt` until end of simulation.

Events are called later as we `step` or `run` through the simulation. They may at runtime create further events and thus cause chains of events to be scheduled and called during simulation.

### Sampling expressions

If we provide the clock with a time interval `Δt`, it ticks with a fixed sample rate. At each tick it will call registered functions or expressions:

- `sample!(sim::Clock, ex::Union{Expr,SimFunction})`: enqueue a function or expression for sampling.

Sampling functions or expressions are called at clock ticks in the sequence they were registered. They are called before any events which may have been scheduled for the same time.

### Running the simulation

Now, after we have setup a clock, scheduled events or setup sampling, we can step or run through a simulation, stop or resume it.

- `run!(sim::Clock, duration::Number)`: run a simulation for a given duration. Call all ticks and scheduled events in that timeframe.
- `incr!(sim::Clock)`: take one simulation step, call the next tick or event.
- `stop!(sim::Clock)`: stop a simulation
- `resume!(sim::Clock)`: resume a halted simulation.

Now we can evaluate the results.

### Logging

Logging enables us to trace variables over simulation time and such analyze their behaviour.

- `L = Logger()`: create a new logger, providing the newest record `L.last`, a logging table `L.df` and a switch `L.ltype` between logging types.
- `init!(L::Logger, sim::Clock=Τ)`:
- `setup!(L::Logger, vars::Array{Symbol})`: setup `L`, providing it with an array of logging variables `[:a, :b, :c ...]`
- `switch!(L::Logger, to::Number=0)`: switch between `0`: only keep the last record, `1`: print, `2`: write records to the table
- `record!(L::Logger)`: record the logging variables with current simulation time.
