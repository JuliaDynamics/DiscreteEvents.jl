# Parallel simulations

Currently `Simulate.jl` enables two approaches to parallel simulations.

## Simulations in parallel

Multiple simulations can be executed on parallel threads using the `@threads`-
macro. Such simulations have different clocks with different times. One example of
this is given in the [dice game example](../examples/dicegame/dicegame.md). This
approach is useful if you do multiple simulations to investigate their response
to parameter variation.

## Multithreading of events and processes  

!!! note

    Multithreading is still experimental and in active development.
    It requires Julia ≥ 1.3.

Big simulations consist of multiple events, sampling functions and asynchronous
processes. All those activities must be coordinated by a clock. In order to avoid
that a single clock becomes the bottleneck of a simulation,

1. you can create a new clock with copies on each available thread with
  [`PClock`](@ref) or you [`fork!`](@ref) an existing single clock to other
  threads. You then have parallel [`ActiveClock`](@ref)s [^1] with events,
  processes and scheduling.  
2. The parallel clocks then are accessible with [`pclock`](@ref). By
  registering events ([`event!`](@ref)), samples ([`sample!`](@ref)) or processes ([`process!`](@ref)) to them as before you then get parallel clock schedules.
3. Or you can tell a clock to randomly spawn events or processes to its
  parallel clocks by setting `spawn=true` in ([`event!`](@ref)) or
  ([`process!`](@ref)) calls. This allows the clock to balance the load between threads.
4. If you [`run!`](@ref) a parallelized clock, the clock on thread 1 becomes
  the "master" clock telling the clocks on the other threads to run for a time
  step Δt and synchronizing with them after each such step.

### Uncertainty of event sequence

This introduces an **uncertainty** into simulations on parallel threads: If an event ```e_x``` has a scheduling time slightly less than event ```e_y```on another thread and both times lie inside the same time interval ```t_x + Δt```, maybe – depending on the thread load – ```e_y``` gets physically executed before ```e_x```. There are several techniques to reduce the uncertainty:

1. If there is a causal connection between two events such that ```e_y``` depends on ```e_x```, the first one can be scheduled ([`event!`](@ref)) with `sync=true` to *force* its execution before the second. But such dependencies are not always known in simulations.
2. You can choose to *group* causally connected events on one thread by scheduling them on a specific parallel clock, such that they are executed in sequence. Consider a factory simulation: also in real factories different departments are decoupled by buffers. You can allocate processes, events and samples of one department together on a thread. See [grouping](@ref grouping) below.
3. You can generally reduce the synchronization cycle Δt such that clocks get synchronized more often.

There is a tradeoff between parallel efficiency and uncertainty: if threads must be synchronized more often, there is more cost of synchronization relative to execution. You have to choose the uncertainty. Often also in simulations as in life such fluctuations in event sequence cancel out statistically and do not matter at all.

### Grouping of events and processes

- grouping parallel simulations with the `@threads` macro,

### Parallel efficiency
- number of threads to use,

see the chapter in performance

### Thread safety
- using random numbers on parallel threads,
- synchronizing write access to shared variables,

[^1]: They are called "active clocks" because they follow the [active object design pattern](https://en.wikipedia.org/wiki/Active_object). They run in event loops, behave internally as state machines and communicate with the master clock across threads via channels following a simple communication protocol.
