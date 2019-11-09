# Troubleshooting

## A SimProcess fails

You can check, if that is the case: if `𝐶` is your clock, you get the list of all running processes with `𝐶.processes`. Than you can look at the failed process with `𝐶.processes[id].task`. This gives you the stack trace of the failed process, e.g.

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
