# Simulate v0.3.0 news (future release notes)

## Breaking changes
- **breaking change**: Logging functions are now removed (they were not useful
  enough).

## New functionality
- Arguments to `SimFunction` can now be given also as symbols, expressions or as
  other SimFunctions. They will then be evaluated at event time before they are
  passed to the event function.
- `Simulate.version` gives now the package version.
- `Simulate.jl` is now faster due to optimizations.

## Deprecated functionality
- Evaluating expressions or symbols at global scope is much slower than using
  `SimFunction`s and gives now a one time warning. This functionality may be
  removed entirely in a future version. (Please write an issue if you want to
  keep it.)
