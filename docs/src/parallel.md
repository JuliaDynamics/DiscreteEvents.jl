# Parallel Simulation

```@meta
CurrentModule = DiscreteEvents
```

You can parallelize simulations in two ways:

1. You can do *independent parallel simulations* with the [`@threads`-macro](https://docs.julialang.org/en/v1/manual/multi-threading/#The-@threads-Macro) [^1] or with the [`Distributed` standard library](https://docs.julialang.org/en/v1/stdlib/Distributed/).
2. You can execute a single simulation on multiple threads to speed it up.

## Multi-Threading (Experimental)

Multithreading of simulations is introduced with `DiscreteEvents` v0.3 and will take some time to become stable. Please try it out and report your problems!

If we compute events of a DES on parallel cores of a computer, we may reverse their sequence ``\;e_i, e_j\;`` to  ``\;e_j, e_i\;``. If there is causality between those events, we have a problem. Therefore we cannot spawn arbitrary events to parallel cores without altering causality and the simulated outcome.

Fortunately not all events in larger DES are strongly coupled. For most practical purposes we can divide systems into subsystems where events depend on each other but not or only statistically on events in other subsystems. Each subsystem has its local time/clock and clocks get synchronized periodically.

## Thread-local Clocks

With [`PClock`](@ref) we introduce parallel local clocks on each thread. When we [`run!`](@ref) the master clock on thread 1, it synchronizes with the parallel clocks each chosen time interval ``\;Δt\;`` . The synchronization takes some time and the slowest thread with the biggest workload (usually thread 1) sets the pace for the whole computation.

We can use [event!](events.md), [periodic!](@ref) and [process!](@ref) to allocate to parallel clocks by using the keywords `cid` or `spawn`. Then

- events and processes get registered to parallel clocks,
- processes get started on parallel threads and
- their functions get the thread local clock to `delay!` or `wait!` on it.

We avoid to share global variables between threads in order not to get race conditions. If thread-local subsystems get inputs from each other, they should communicate over Julia channels, which are thread safe.

When working on parallel threads, we have thread-local random number generators. Random number sequences therefore are not identical between single-threaded and multithreaded applications (see below). This usually causes also simulation results to be different.

## Speedup and Balance

First results show a considerable speedup of multithreaded simulations vs single-threaded ones:

1. The [Multithreaded Assembly Line](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/examples/assy_thrd/) on `DiscreteEventsCompanion` took 1.58 s to run 63452 events on 8 parallel cores vs. 70287 events in 10.77 s on thread 1 of the same machine [^2].
2. If we put the simulated assembly operations only on threads 2-8, it took only 0.67 s.
3. With all assembly operations together on thread 2, it took 4.96 s.

The 2nd and 3rd results show that considerable speedups can yet be realized by relieving thread 1 and distributing the workload between the other ones.

## Random Numbers

To get reproducible but different random number sequences on each thread, you can seed the [thread-specific global default random number generators](https://julialang.org/blog/2019/07/multithreading/#random_number_generation) with [`pseed!`](@ref). It will `seed!` the thread-specific default RNGs with the given number multiplied by the thread id ``n\times t_i``. Calls to `rand()` are thread-specific and will then use the seeded default RNGs.

At this time of writing all implicit calls to `rand()` in timed [`event!`](@ref event!(::CL,::A,::U)  where {CL<:AbstractClock,A<:Action,U<:Number})s or in [`delay!`](@ref) use the default RNGs.

Alternatively you can seed a thread-specific default RNG with:

```julia
using DiscreteEvents, Random

onthread(2) do  # seed the default RNG on thread 2
    Random.seed!(123)
end
```

## Documentation and Examples

You can find more [documentation](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/parallel/) and [examples](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/examples/examples/#Multi-Threading-(Experimental)) on `DiscreteEventsCompanion`.

[^1]:  [Goldratt's Dice Game](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/examples/dicegame/dicegame/) on `DiscreteEventsCompanion` illustrates how to do this.
[^2]: Event numbers and line throughput are different because the random number sequence changes between these examples.
