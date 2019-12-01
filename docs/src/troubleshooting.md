# Troubleshooting

## Problems

### Process startup

Under some environments (e.g. Jupyter) between starting processes with `process!` and running a simulation a little sleep, e.g. `sleep!(0.1)` is needed before running a simulation with `run!` to ensure that all started processes have enqueued for clock events.

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
Closest candidates are:
  round(::Float64, ::RoundingMode{:Nearest}) at float.jl:370
  round(::Float64, ::RoundingMode{:Up}) at float.jl:368
  round(::Float64, ::RoundingMode{:Down}) at float.jl:366
  ...
logevent(::Int64, ::Channel{Any}, ::String, ::Int64) at ./In[6]:12
people(::Channel{Any}, ::Channel{Any}, ::Float64) at ./In[17]:8
loop(::SimProcess) at /Users/paul/.julia/packages/Simulate/BOeZP/src/process.jl:37
(::getfield(Simulate, Symbol("##19#20")){SimProcess})() at ./task.jl:268
```

## Report

Otherwise please report your problem and open an issue at https://github.com/pbayer/Simulate.jl.  
