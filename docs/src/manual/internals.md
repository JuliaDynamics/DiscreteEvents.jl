# Internals

```@meta
CurrentModule = Simulate
```

## Clocks

```@docs
AbstractClock
```

`Simulate.jl` contains several clock types: [`Clock`](@ref), [`ActiveClock`](@ref) and [`RTClock`](@ref). They are implemented as state machines. Their implementation are internal and not exported.
