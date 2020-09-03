#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

"""
    onthread(f::F, tid::Int; wait::Bool=true) where {F<:Function}

Execute a function `f` on thread `tid`. 
    
To execute `f` on a thread other than 1 can speed it up 
significantly if it depends on asynchronous tasks.

# Arguments
- `f::Function`:     function to execute
- `tid::Int`:        thread id
- `wait::Bool=true`: if true, it waits for function to finish

# Example
```jldoctest
julia> using DiscreteEvents, .Threads

julia> onthread(2) do; threadid(); end
2
```
"""
function onthread(f::F, tid::Int; wait::Bool=true) where {F<:Function}
    t = Task(nothing)
    @assert tid in 1:nthreads() "thread $tid not available!"
    @threads for i in 1:nthreads()
        if i == tid
            t = @async f()
        end
    end
    wait && fetch(t)
end

"""
```
pseed!(s::Int)
```
Seed each of the thread local RNGs with `s*threadid()` to get 
reproducible, but different random number sequences on each thread.
"""
function pseed!(s::Int)
    @threads for i in 1:nthreads()
        Random.seed!(s*i)
    end
end
