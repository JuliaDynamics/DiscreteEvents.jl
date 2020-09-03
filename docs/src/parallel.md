# Parallel Simulation

```@meta
CurrentModule = DiscreteEvents
```

You can parallelize simulations in two ways:

1. You can do *independent parallel simulations* with the [`@threads`-macro](https://docs.julialang.org/en/v1/manual/multi-threading/#The-@threads-Macro) [^1] or with the [`Distributed` standard library](https://docs.julialang.org/en/v1/stdlib/Distributed/).
2. You can execute a single simulation on multiple threads to speed it up.

## Multithreading

!!! warning "Multithreading is experimental!"

    Multithreading of simulations gets introduced with `DiscreteEvents` v0.3 and will take some time to be considered as stable. Please try it out and report your problems!

- Warning: There is no free lunch
- Prerequisites for multithreading simulations
- Process/setup
- Avoid shared variables between threads
- example

## Random Numbers

To get reproducible but different random number sequences on each thread you can seed the [thread-specific global default random number generator](https://julialang.org/blog/2019/07/multithreading/#random_number_generation) with [`pseed!`](@ref). Then the thread-specific default RNG will be seeded with the given seed multiplied by the thread number ``s\times n_t``. Calls to `rand()` are thread-specific and will use the seeded default RNG.

At this time of writing all implicit calls to `rand()` in timed [`event!`](@ref event!(::CL,::A,::U)  where {CL<:AbstractClock,A<:Action,U<:Number})s or in [`delay!`](@ref) use the default RNG.

Alternatively you can set the thread-specific default RNG with:

```julia
using DiscreteEvents, Random

onthread(2) do  # seed the default RNG on thread 2
    Random.seed!(123)
end
```

[^1]: The [Goldratt's Dice Game](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/examples/dicegame/dicegame/) example on `DiscreteEventsCompanion` illustrates how to do this.