# News in v0.3.1

```@meta
CurrentModule = DiscreteEvents
```

Few days after the release of v0.3.0 Hector Perez contributed macros to be used for common cases:

- [`@event`](@ref): create an event, wraps [`fun`](@ref) and [`event!`](@ref) into one call,
- [`@process`](@ref): create a process, wraps [`Prc`](@ref) and [`process!`](@ref) into one call,
- [`@wait`](@ref): simplified call of [`wait!`](@ref),

The following macros provide syntactic sugar to existing functions:

- [`@delay`](@ref): calls [`delay!`](@ref),
- [`@run!`](@ref): calls [`run!`](@ref).

## Earlier releases

- [**Release notes**](history.md): A look at earlier releases.
