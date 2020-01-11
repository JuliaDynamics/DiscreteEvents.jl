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
minimum     2020-01-11T12:03:01.529       84.189      322.629         64.191         471.009
mean        2020-01-11T12:03:01.529       85.611      340.396         70.126         496.133

action times:
-------------
time        datetime                channel [μs]    dice [μs]   heating [μs]    overall [μs]
minimum     2020-01-11T12:03:01.529       34.532       66.521         20.534          45.228
mean        2020-01-11T12:03:01.529       35.115       70.185         22.433          47.641
                                                       ^^^^^^
```

The most interesting thing to note is, that actions for a process based simulation
(dice) take twice the time than for an event based one (channel). This shows that
task switching comes with a cost.  

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
