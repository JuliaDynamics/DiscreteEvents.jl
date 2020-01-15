# News

## Breaking changes in v0.3.0
- **breaking change**: Logging functions are now removed (they were not useful
  enough).

## New functionality in v0.3.0
- Arguments to `SimFunction` can now be given also as symbols, expressions or as
  other SimFunctions. They get evaluated at event time before being
  passed to the event function,
- [`Simulate.version`](@ref) gives now the package version,
- `Simulate.jl` is now faster due to optimizations,
- [`process!`](@ref) can now `spawn` tasks to parallel threads,
- multithreading of events and processes --> still in development

## Deprecated functionality in v0.3.0
- Evaluating expressions or symbols at global scope is much slower than using
  `SimFunction`s and gives now a one time warning. This functionality may be
  removed entirely in a future version. (Please write an issue if you want to
  keep it.)

## Earlier releases

- [**Release notes**](manual/history.md): A look at earlier releases.
