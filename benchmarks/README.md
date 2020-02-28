# Benchmarks

This contains benchmark programs and results.

- `bench_channel.jl`: event based with long queues for timed and conditional events,
- `bench_dice.jl`: process based without sampling,
- `bench_heating.jl`: mixed events, processes and sampling,
- `bench_all.jl`: combined benchmark,
- `bench_all_min.csv`: results table, minimum benchmark times,
- `bench_all_mean.csv`: results table, mean benchmark times,

## Overview

| benchmark | `bench_channel.jl` | `bench_dice.jl`| `bench_heating.jl` | sum |
|-------------------|-----:|-----:|-----:|------:|
| **events**        | 1000 | 4847 | 246  | 6043  |
| **sample steps**  | 1438 |    0 | 2880 | 4318  |
| **actions**       | 2438 | 4847 | 3126 | 10411 |

The benchmarks generate 6043 simulation events and 4318 sampling steps, 10411
actions overall and measure their duration.

## Current results (v0.3.0dev)
```
Benchmark results:
==================
time        datetime                channel [ms]    dice [ms]   heating [ms]        sum [ms]
minimum     2020-02-27T16:56:14.647       44.630       36.641          5.091          86.362
mean        2020-02-27T16:56:14.647       46.213       38.476          5.966          90.656

action times:
-------------
time        datetime                channel [μs]    dice [μs]   heating [μs]    overall [μs]
minimum     2020-02-27T16:56:14.647       18.083        7.555          1.629           8.269
mean        2020-02-27T16:56:14.647       18.725        7.933          1.908           8.680
```

## Platform
Benchmarks were taken on a single thread (dice and heating on thread 2) on a
2013 MacBook Pro:

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
