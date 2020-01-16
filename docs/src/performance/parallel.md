# Parallel simulations

Currently `Simulate.jl` enables three approaches to parallel simulations.

## Simulations in parallel

In this case multiple simulations are executed on parallel threads using the `@threads`-macro. Such simulations have different clocks with different times. One example of this is given in the [dice game example](../examples/dicegame/dicegame.md). This approach is useful if you want to check, how simulation models respond to parameter variation.

## Processes on multiple threads

When using Julia ≥ 1.3 you can spawn processes on multiple threads by starting
them with [`process!`](@ref) and `spawn=true`. A process may then run on another thread than the clock to which it reports. Each call to or from the clock
requires a synchronization between threads. This is efficient only with not
too lightweight processes.

--> benchmarks needed.

## Multithreading of events and processes  

!!! warn

    Multithreading in that sense is still experimental and in active development

Big simulations consist of multiple events, sampling functions and asynchronous
processes. In order to avoid that a single clock becomes the bottleneck of a
simulation, we [`multiply!`](@ref) it to each available thread. Then we have  
multiple [active clock](@ref ActiveClock) with events and scheduling. Time gets
synchronized to the master clock on thread 1 at each time step Δt or sooner if
requested. In the meantime events are registered, scheduled and computed in
parallel on each thread.

- using random numbers on parallel threads
- number of threads to use
