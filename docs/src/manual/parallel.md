# Parallel simulations

Currently `Simulate.jl` enables two approaches to parallel simulations.

## Simulations in parallel

Multiple simulations can be executed on parallel threads using the `@threads`-
macro. Such simulations have different clocks with different times. One example of
this is given in the [dice game example](../examples/dicegame/dicegame.md). This
approach is useful if you do multiple simulations to investigate their response
to parameter variation. Basically you write a function, accepting parameters and doing a simulation on them. You then can invoke multiple simulations in a for loop:

```julia
```

## Multithreading of events and processes  

!!! note

    Multithreading is still experimental and in active development.
    It requires Julia ≥ 1.3.

Simulations consist of multiple events, sampling functions and asynchronous
processes. The clock executes them sequentially on one thread. But modern computers have multiple cores, each being able to execute at least one distinct thread of operations. In order to speed things up, you may want to use the other cores (threads) as well:

1. With  [`PClock`](@ref) you can create a clock with copies on each available thread  or you can [`fork!`](@ref) an existing single clock to other threads. Then there are parallel [`ActiveClock`](@ref)s [^1] for scheduling and execution of  parallel events,  processes and samples.  
2. Parallel clocks are accessible with [`pclock`](@ref). By  registering events ([`event!`](@ref)), samples ([`sample!`](@ref)) or processes ([`process!`](@ref)) to them you get parallel clock schedules.
3. You can also schedule events or processes randomly on parallel clocks by calling [`event!`](@ref), [`process!`](@ref) or [`sample!`](@ref) with `spawn=true`. This allows to balance the load between threads.
4. If you [`run!`](@ref) a parallelized clock, the clock on thread 1 becomes the "master", tells the clocks on the other threads to run for a time step Δt and synchronizes with them after each such step.

```julia
```

### Uncertainty of event sequence

Multithreading introduces an **uncertainty** into simulations: If an event ``e_x`` has a scheduling time before event ``e_y`` on another thread both lying inside the same time interval ``t_x + Δt``, maybe – depending on differing thread loads – ``e_y`` gets executed before ``e_x``. There are several techniques to reduce this uncertainty:

1. If there is a causal connection between two events such that ``e_y`` depends on ``e_x``, the first one can be scheduled as [`event!`](@ref) with `sync=true` to *force* its execution before the second. But such dependencies are not always known beforehand in simulations.
2. You can choose to *group* causally connected events on one thread by scheduling them together on a specific parallel clock, such that they are executed in sequence. Consider a factory simulation: in real factories shops are often decoupled by buffers. You can allocate processes, events and samples of each shop  together on a thread. See [grouping](@ref grouping) below.
3. You can generally reduce the synchronization cycle Δt such that clocks get synchronized more often.

There is a tradeoff between parallel efficiency and uncertainty: if threads must be synchronized more often, there is more cost of synchronization relative to execution. You have to choose the uncertainty you are willing to pay to gain parallel efficiency. Often in simulations as in life fluctuations in event sequence cancel out statistically and can be neglected.

### [Grouping of events and processes](@id grouping)

- explicit grouping of events, processes and samples to parallel clocks,
- grouping them with the `@threads` macro,

### Parallel efficiency
- number of threads to use,

see the chapter in performance

### Thread safety
- using random numbers on parallel threads,
- synchronizing write access to shared variables,

[^1]: They are called "active clocks" because they follow the [active object design pattern](https://en.wikipedia.org/wiki/Active_object). They run in event loops, behave internally as state machines and communicate with the master clock across threads via channels following a simple communication protocol.
