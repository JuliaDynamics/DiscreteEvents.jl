# Troubleshooting

## Problems

### Process startup

Under some environments (e.g. Jupyter) it may happen, that the processes have not started completely before the clock runs. In such cases it may help to put a little sleep, e.g. `sleep!(0.1)` between `process!(…)` and `run!(…)` to ensure that all started processes have enqueued for clock events.

### Clock information

Normally for clocks pretty printing is enabled. For diagnostic purposes you can
switch pretty printing off and on:

```julia
julia> clk = Clock()
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0

julia> Simulate._show_default[1] = true;

julia> clk
Clock(0, Simulate.Undefined(), 0.0, , 0.0, Simulate.AC[], Simulate.Schedule(DataStructures.PriorityQueue{Simulate.DiscreteEvent,Float64,Base.Order.ForwardOrdering}(), Simulate.DiscreteCond[], Simulate.Sample[]), Dict{Any,Prc}(), 0.0, 0.0, 0.0, 0, 0)

julia> Simulate._show_default[1] = false;

julia> clk
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0
```

### A process fails

If `c` is your clock, you get the list of all running processes with `c.processes`. You  then look at the failed process with `c.processes[id].task`. This gives you the stack trace of the failed process, e.g.

```julia
julia> 𝐶.processes
Dict{Any,Prc} with 2 entries:
  2 => Prc(2, Task (failed) @0x000000010e467850, Idle(), clerk, Channel{…
  1 => Prc(1, Task (failed) @0x000000010e467cd0, Idle(), people, Channel…
julia> 𝐶.processes[1].task
Task (failed) @0x000000010e467cd0
MethodError: no method matching round(::Float64, ::Int64)
[....]
```

## Report

Otherwise please report your problem and open an issue or commit your solution to [the repo](https://github.com/pbayer/Simulate.jl).  
