## Parallel Clocks (Experimental)

Parallel clocks are a new feature in v0.3 and cannot yet considered to be stable. Please develop your applications first single-threaded before going parallel. Please report any failures.

Parallel clocks are virtual clocks with local clocks on parallel threads to support multi-threaded simulations.

A parallel clock structure consists of a master (global) clock on thread 1 and [`ActiveClock`](@ref)s on all available threads > 1. An active clock is a task running a thread local clock. The thread local clock can schedule and execute events locally.

The master clock communicates with its parallel active clocks via message channels. It synchronizes time with the local clocks. Tasks (processes and actors) have access to their thread local clock from it and then work only with the local clock.

```@docs
PClock
pclock
```

Parallel clocks can be identified by their thread number: the master clock works on thread 1, local clocks on parallel threads ≥ 2. They can be setup and accessed easily:

```@repl clocks
@show x=nthreads()-1;
clk = PClock()       # now the clock has (+x) active parallel clocks
ac2 = pclock(clk, 2) # access the active clock on thread 2
ac2.clock            # the thread local clock
ac2.clock.ac[]       # local clocks can access their active clock
```

Tasks on parallel threads have access to the thread local clock by `pclock(clk)`. Then they can schedule events, `delay!` or `wait!` on it as usual. The thread local clock is passed to a `process!` automatically if you set it up on a parallel thread.

You can fork explicitly existing clocks to other threads or collapse them if no longer needed. You can get direct access to parallel active clocks and diagnose them.

```@docs
fork!
collapse!
```

```@repl clocks
clk = Clock()      # create a clock
fork!(clk)         # fork it
clk                # it now has parallel clocks
collapse!(clk)     # collapse it
clk                # it now has no parallel clocks
```

```@docs
diagnose
```
