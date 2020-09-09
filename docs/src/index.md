# DiscreteEvents.jl

A Julia package for **discrete event generation and simulation**.

`DiscreteEvents.jl` [^1] introduces a *clock* and allows to schedule arbitrary functions or expressions as *actions* on the clock's timeline. It provides simple, yet powerful ways to model and simulate discrete event systems (DES).

## Overview

- [**NEWS**](news.md): What is new about this version?
- [**Introduction**](intro.md): Get an overview and learn the basics.
- [**Manual**](clocks.md): Get detailed informations about types, functions and macros.
- [**Internals**](internals.md): some internal types and functions.
- [**Troubleshooting**](troubleshooting.md): If something doesn't work as expected.
- [**Version history**](history.md): A list of features and changes.

## Companion

There is a companion site [DiscreteEventsCompanion](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/) with more information, examples, notebooks and benchmarks.

## Development

`DiscreteEvents` is in active development. Please use, test and help  evolve it. Its GitHub repository is at [https://github.com/pbayer/DiscreteEvents.jl](https://github.com/pbayer/DiscreteEvents.jl).

**Author:** Paul Bayer
**License:** MIT

[^1]: `DiscreteEvents.jl` as of `v0.3` has been renamed from [`Simulate.jl`](https://github.com/pbayer/Simulate.jl/tree/v0.2.0), see [issue #13](https://github.com/pbayer/DiscreteEvents.jl/issues/13).
