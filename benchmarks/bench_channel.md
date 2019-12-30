# Channel benchmarks

source: `bench_channel.jl`

benchmarks were done with:
```julia
julia> versioninfo()
Julia Version 1.3.0
Commit 46ce4d7933 (2019-11-26 06:09 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin19.0.0)
  CPU: Intel(R) Core(TM) i7-4850HQ CPU @ 2.30GHz
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-6.0.1 (ORCJIT, haswell)
Environment:
  JULIA_NUM_THREADS = 4
```

## First benchmark

2019-12-27:

    0.009447 seconds (2.55 k allocations: 153.891 KiB)
    0.397957 seconds (2.48 M allocations: 115.761 MiB, 6.75% gc time)
    run! finished with 1000 clock events, 1438 sample steps, simulation time: 500.0
    result=3.137592669589475
    BenchmarkTools.Trial:
    memory estimate:  115.75 MiB
    allocs estimate:  2481210
    --------------
    minimum time:     351.639 ms (2.16% GC)
    median time:      357.934 ms (3.11% GC)
    mean time:        359.288 ms (2.85% GC)
    maximum time:     374.970 ms (3.21% GC)
    --------------
    samples:          27
    evals/sample:     1

## Optimization of `simExec()` and `exec_next_tick()`

2019-12-28:

    0.000242 seconds (2.55 k allocations: 153.891 KiB)
    0.250356 seconds (1.76 M allocations: 66.291 MiB, 3.09% gc time)
    run! finished with 1000 clock events, 1438 sample steps, simulation time: 500.0
    result=3.137592669589475
    BenchmarkTools.Trial:
    memory estimate:  66.29 MiB
    allocs estimate:  1760476
    --------------
    minimum time:     238.719 ms (1.99% GC)
    median time:      244.762 ms (3.04% GC)
    mean time:        244.845 ms (3.04% GC)
    maximum time:     265.542 ms (1.98% GC)
    --------------
    samples:          50
    evals/sample:     1

speedup: 1.473\
**Note:** The DOE-example in Goldratt's dice-game speeds up 4x with this
optimization, 4.02 instead of 17.47 minutes

## Replace `Array`s with `Tuple`s and comprehensions with `map`

2019-12-29

    2019-12-29 T17:43:54.573
      0.000202 seconds (2.05 k allocations: 67.953 KiB)
      0.173119 seconds (1.59 M allocations: 34.860 MiB)
    run! finished with 1000 clock events, 1438 sample steps, simulation time: 500.0
    result=3.137592669589475
    BenchmarkTools.Trial:
      memory estimate:  34.85 MiB
      allocs estimate:  1587418
      --------------
      minimum time:     166.838 ms (0.00% GC)
      median time:      172.417 ms (2.36% GC)
      mean time:        173.043 ms (1.88% GC)
      maximum time:     190.001 ms (0.00% GC)
      --------------
      samples:          50
      evals/sample:     1

speedup: 2.108 (relative to first benchmark)\
**Note:** The DOE-example in Goldratt's dice-game takes longer again with this
optimization: 7.23 minutes. This shows that we need **different benchmarks**.
