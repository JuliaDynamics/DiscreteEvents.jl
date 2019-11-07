### Discrete event simulation with `Simulate.jl`

1. [`Simulate.jl`](https://github.com/pbayer/Simulate.jl) evaluates Julia expressions or arbitrary functions at given (virtual) simulation times.
2. Thus discrete event systems based on state machines can be modeled and simulated.
3. Variables can be logged over simulation time and then accessed for
analysis or visualization.

### The clock

`Simulate.jl` provides a clock for a simulation time  (a `Float64`) with an arbitrary unit of time. A unit can be set and times can be given to the clock with `Unitful` time units and thus are automatically converted.

- `Clock(Δt::Number=0; t0::Number=0, unit::FreeUnits=NoUnits)`: create a new clock with sampling time `Δt`, start time `t0` and a choosen `Unitful` time unit.
- italic `𝐶` (`\itC`+Tab) or `Clk` : is the central Clock() variable.
- `τ(sim::Clock=𝐶)`: return the current clock time.
- `sample_time!(sim::Clock, Δt::Number)`: set the clock's sample rate starting from `now(sim)`.
- `reset!(sim::Clock, Δt::Number=0; t0::Time=0, hard::Bool=true)`: reset a clock.
- `sync!(sim::Clock, to::Clock=𝐶)`: Force a synchronization of two clocks.

If no Δt ≠ 0 is given, the simulation doesn't tick with a fixed interval, but jumps from event to event.

#### A note on using time units

Internally `Simulate` clocks work with a `Float64` time and it works per default with `Unitful.NoUnits` but you can set them to work with `Unitful.Time` units like `ms, s, minute, hr`. In this case `τ(c)` returns a time, e.g. `1 s`. You can also provide time values to clocks or in scheduling events. They then are converted to the defined unit as long as the clock is set to a time unit.

- `setUnit(sim::Clock, unit::FreeUnits)`: set a clock unit.
- `τ(sim::Clock).val`: return unitless number for current time.

At the moment I find it unconvenient to work with units if you trace simulation times in a table or you do plots. It seems easier not to use them as long you need automatic time conversion in your simulation projects.

### Functions and expressions as Events

Julia functions or expressions are scheduled as events on the clock's time line:

- `SimFunction(func::Function, arg...; kw...)`: prepare a function and its arguments for simulation.
- `event!(sim::Clock, ex::Union{Expr,SimFunction}, t::Number)` or
- `event!(sim, ex, at, t)`: schedule a function or an expression for a given simulation time.
- `event!(sim, ex, after, t):` schedule a function or an expression for time `t` after current simulation time.
- `event!(sim, ex, every, Δt)`: schedule a function an expression for now and every time step `Δt` until end of simulation.

Events are called later as we `step` or `run` through the simulation. They may at runtime create further events and thus cause chains of events to be scheduled and called during simulation.

### Sampling expressions

If we provide the clock with a time interval `Δt`, it ticks with a fixed sample rate. At each tick it will call registered functions or expressions:

- `sample_time!(sim::Clock, Δt::Number)`: set the clock's sampling time starting from now (`τ(sim)`).
- `sample!(sim::Clock, ex::Union{Expr,SimFunction})`: enqueue a function or expression for sampling.

Sampling functions or expressions are called at clock ticks in the sequence they were registered. They are called before any events scheduled for the same time.

### Functions as processes

If they match certain conditions, functions can be started as processes, which
wait for inputs, respond accordingly and create some output.

- `SimProcess(id, func::Function, in::Channel=Channel(Inf), out::Channel=Channel(Inf), arg...; kw...)`: prepare a function `func(in::Channel, out::Channel, arg...; kw...)` for
running as a process in a simulation.
- `process!(sim::Clock, p::SimProcess)`: register a `SimProcess` to a clock
- `start!(sim::Clock)`: start all registered `SimProcess`es.
- `stop!(p::SimProcess)`: stop `p`.
- `delay!(sim::Clock, t::Number)`: a process can call for a delay, which creates
an event on the clock's timeline and wakes up the process after the given `t`.

!!! note
    A function `f` running as a `SimProcess` is put in a loop. So it has to
    give back control by e.g. doing a `take!(in)` on its input channel or by calling
    `delay!` etc., which will `yield` it. Otherwise it will after start starve
    everything else!

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
- `init!(L::Logger, sim::Clock=𝐶)`:
- `setup!(L::Logger, vars::Array{Symbol})`: setup `L`, providing it with an array of logging variables `[:a, :b, :c ...]`
- `switch!(L::Logger, to::Number=0)`: switch between `0`: only keep the last record, `1`: print, `2`: write records to the table
- `record!(L::Logger)`: record the logging variables with current simulation time.
