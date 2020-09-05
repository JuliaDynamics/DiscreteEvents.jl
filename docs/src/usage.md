# Utilities

## Single-threaded Speed-up

The Julia scheduler is running on thread 1. If your application uses tasks or channels on thread 1 (e.g. with [`process!`](@ref)), it has to compete against other background tasks. You can remove this competition and speed up your application significantly (often by ``\times10`` or more) by moving it to a thread other than 1.

```@docs
onthread
```

Look at the [M/M/c benchmarks](https://github.com/pbayer/DiscreteEventsCompanion.jl/tree/master/benchmarks/queue_mmc) and to [this example](https://github.com/pbayer/DiscreteEventsCompanion.jl/blob/master/benchmarks/queue_mmc/bench_queue_mmc_srv1.jl) on `DiscreteEventsCompanion` for an illustration. You cannot speedup applications not using tasks or channels with this technique.

## Parallel RNG Seed

```@docs
pseed!
```
