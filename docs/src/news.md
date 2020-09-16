# News in v0.3.1

```@meta
CurrentModule = DiscreteEvents
```

A few days after the release of v0.3.0 Hector Perez contributed some macros to make the `DiscreteEvents` API more Julian for common cases:

- [`@event`](@ref): wraps [`fun`](@ref) and [`event!`](@ref) into one call,
- [`@periodic`](@ref): wraps [`fun`](@ref) and [`periodic!`](@ref) into one call,
- [`@process`](@ref): wraps [`Prc`](@ref) and [`process!`](@ref) into one call,
- [`@wait`](@ref): simplified call of [`wait!`](@ref),

The following macros provide syntactic sugar to existing functions:

- [`@delay`](@ref): calls [`delay!`](@ref),
- [`@run!`](@ref): calls [`run!`](@ref).

## Earlier releases

- [**Release notes**](history.md): A look at earlier releases.
