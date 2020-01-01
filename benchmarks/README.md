# Benchmarks

This contains benchmark programs and results.

- `bench_channel.jl`: event based with long queues for timed and conditional events,
- `bench_dice.jl`: process based without sampling,
- `bench_heating.jl`: mixed events, processes and sampling,
- `bench_all.jl`: combined benchmark,
- `bench_all_min.csv`: results table, minimum benchmark times,
- `bench_all_mean.csv`: results table, mean benchmark times,

## Overview

| benchmark program  | events | sample steps | sum (actions) |
|--------------------|-------:|-------------:|--------------:|
| `bench_channel.jl` |   1000 |         1438 |          2438 |
| `bench_dice.jl`    |   4847 |            - |          4847 |
| `bench_heating.jl` |    246 |         2880 |          3126 |
| sum                |   6043 |         4318 |         10411 |


The benchmarks generate 6043 simulation events and 4318 sampling steps, 10411
actions overall and measure their duration.

## Current results (v0.3.0dev)
```
Benchmark results:
==================
time        datetime                channel [ms]    dice [ms]   heating [ms]        sum [ms]
minimum     2020-01-01T18:25:20.993       93.933      374.012        125.974         593.919
mean        2020-01-01T18:25:20.993       96.945      398.542        140.913         636.400

action times:
-------------
time        datetime                channel [μs]    dice [μs]   heating [μs]    overall [μs]
minimum     2020-01-01T18:25:20.993       38.529       77.116         40.299          57.031
mean        2020-01-01T18:25:20.993       39.764       82.174         45.078          61.110
```

The most interesting thing to note is, that actions for a process based simulation
(dice) take twice the time than for an event based one (channel). This shows that
task switching and blocking on channels come with a cost.  

## Platform
Benchmarks were taken on a single thread on

```julia
julia> versioninfo()
Julia Version 1.3.1
Commit 2d5741174c (2019-12-30 21:36 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin18.6.0)
  CPU: Intel(R) Core(TM) i7-4850HQ CPU @ 2.30GHz
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-6.0.1 (ORCJIT, haswell)
```
