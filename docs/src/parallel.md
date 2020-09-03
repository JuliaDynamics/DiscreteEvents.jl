# Parallel Simulation

```@meta
CurrentModule = DiscreteEvents
```

You can parallelize simulations in two ways:

1. You can do *independent parallel simulations* with the [`@threads`-macro](https://docs.julialang.org/en/v1/manual/multi-threading/#The-@threads-Macro) [^1] or with the [`Distributed` standard library](https://docs.julialang.org/en/v1/stdlib/Distributed/).
2. You can execute a single simulation on multiple threads to speed it up.

## Multithreading

!!! warning "Multithreading is experimental!"

    Multithreading of simulations is introduced with `DiscreteEvents` v0.3 and will take some time to become stable. Please try it out and report your problems!

If we compute events of a DES on parallel cores of a computer, we may reverse their sequence ``\;e_i, e_j\;`` to  ``\;e_j, e_i\;``. If there is causality between those events, we got a problem. Therefore we cannot spawn arbitrary events to parallel cores without altering causality.

Fortunately not all events in larger DES are strongly coupled. For most practical purposes we can divide systems into subsystems where events depend on each other but not on events in other subsystems. Each subsystem has a local time/clock and clocks get synchronized periodically.

## Thread-local Clocks

With [`PClock`](@ref) we introduce parallel local clocks on each thread which get synchronized each chosen time interval ``\;Δt\;`` if we [`run!`](@ref) the master clock on thread 1. The synchronization takes some time and the slowest thread with the biggest workload sets the pace for the whole computation.

If we allocate [events](events.md), [periodic](@ref) actions and [processes](@ref) to parallel clocks by giving them a clock id `cid` or by spawning them with `spawn`, events and processes get registered to parallel clocks and processes get started on parallel threads and their functions get the thread local clock to `delay!` or `wait!` on it.

We must not share global variables between threads in order to avoid race conditions. If thread-local subsystems get inputs from each other, they should communicate over Julia channels, which are thread safe.

When working on parallel threads we get thread-local random number generators. Therefore random number sequences are not the same between single-threaded and multithreaded applications (see below).

## Speedup and Balance

First results show a considerable speedup of multithreaded simulations vs single-threaded ones:

1. The Multithreaded Assembly Line on `DiscreteEventsCompanion` run 66577 events in 1.55 s on 8 parallel cores vs. 70287 events in 10.77 s on thread 1 of the same machine [^2].
2. If we put the simulated assembly operations only on threads 2-8, it took 0.67 s.
3. If we run all assembly operations on thread 2, it took 4.96 s.

The 2nd and 3rd results show that considerable speedups can yet be realized by relieving thread 1 and distributing the workload between the other ones.

## Random Numbers

To get reproducible but different random number sequences on each thread, you can seed the [thread-specific global default random number generators](https://julialang.org/blog/2019/07/multithreading/#random_number_generation) with [`pseed!`](@ref). It will `seed!` the thread-specific default RNGs with the given number multiplied by the thread id ``n\times t_i``. Calls to `rand()` are thread-specific and will then use the seeded default RNGs.

At this time of writing all implicit calls to `rand()` in timed [`event!`](@ref event!(::CL,::A,::U)  where {CL<:AbstractClock,A<:Action,U<:Number})s or in [`delay!`](@ref) use the default RNGs.

Alternatively you can set the thread-specific default RNG with:

```julia
using DiscreteEvents, Random

onthread(2) do  # seed the default RNG on thread 2
    Random.seed!(123)
end
```

## More Documentation and Examples

You can find more [documentation](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/parallel/) and examples on `DiscreteEventsCompanion`.

[^1]: The [Goldratt's Dice Game](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/examples/dicegame/dicegame/) example on `DiscreteEventsCompanion` illustrates how to do this.
[^2]: Event numbers and line throughput are different because the random number sequence changes between these examples.