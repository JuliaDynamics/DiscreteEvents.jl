# Troubleshooting

## Problems

### Process startup

Under some environments (e.g. Jupyter) it may happen, that the processes have not started completely before the clock runs. In such cases it may help to put a little sleep, e.g. `sleep!(0.1)` between `process!(…)` and `run!(…)` to ensure that all started processes have enqueued for clock events.

### A SimProcess fails

If `c` is your clock, you get the list of all running processes with `c.processes`. You  then look at the failed process with `c.processes[id].task`. This gives you the stack trace of the failed process, e.g.

```julia
julia> 𝐶.processes
Dict{Any,SimProcess} with 2 entries:
  2 => SimProcess(2, Task (failed) @0x000000010e467850, Idle(), clerk, Channel{…
  1 => SimProcess(1, Task (failed) @0x000000010e467cd0, Idle(), people, Channel…
julia> 𝐶.processes[1].task
Task (failed) @0x000000010e467cd0
MethodError: no method matching round(::Float64, ::Int64)
[....]
```

## Report

Otherwise please report your problem and open an issue or commit your solution to [the repo](https://github.com/pbayer/Simulate.jl).  
