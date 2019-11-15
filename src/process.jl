#
# routines for handling functions as processes
#

"""
```
process!(sim::Clock, p::SimProcess)
```
Register a `SimProcess` to a clock and return the `id` it was registered with.
It can then be found under `sim.processes[id]`.
"""
function process!(sim::Clock, p::SimProcess)
    id = p.id
    while haskey(sim.processes, id)
        if isa(id, Float64)
            id = nextfloat(id)
        elseif isa(id, Int)
            id += 1
        elseif isa(id, String)
            s = split(id, "#")
            id = length(s) > 1 ? chop(id)*string(s[end][end]+1) : id*"#1"
        else
            throw(ArgumentError("process id $id is duplicate, cannot convert!"))
        end
    end
    sim.processes[id] = p
    p.id = id
end
process!(p::SimProcess) = process!(𝐶, p)

"""
    loop(p::SimProcess)

Put a `SimProcess` in a loop, which can be broken by a `SimException`.
"""
function loop(p::SimProcess, start::Channel)
    take!(start)
    while true
        try
            p.func(p.input, p.output, p.arg...; p.kw...)
        catch exc
            if isa(exc, SimException)
                exc.ev == Stop() ? break : nothing
            end
            rethrow(exc)
        end
    end
end

"""
    startup!(p::SimProcess)

Start a `SimProcess` as a task in a loop.
"""
function startup!(p::SimProcess)
    start = Channel(0)
    p.task = @async loop(p, start)
    p.state = Idle()
    put!(start, 1) # let the process start
end

"start a new SimProcess"
step!(p::SimProcess, ::Undefined, ::Start) = startup!(p)

"start a halted SimProcess"
step!(p::SimProcess, ::Halted, ::Resume) = startup!(p)

"stop a SimProcess"
function step!(p::SimProcess, ::Idle, ::Stop)
    schedule(p.task, SimException(Stop()))
    yield()
    p.state = Halted()
end

"""
```
delay!(sim::Clock, t::Number)
delay!(t::Number)
```
Delay a process for a time interval `t` on the clock `sim`. Suspend the calling
process until being reactivated by the clock at the appropriate time.

# Arguments
- `sim::Clock`: clock, if no clock is given, the delay goes to `𝐶`.
- `t::Number`: the time interval for the delay.
"""
function delay!(sim::Clock, t::Number)
    c = Channel(0)
    event!(sim, SimFunction(put!, c, t), after, t)
    take!(c)
end
delay!(t::Number) = delay!(𝐶, t)

"""
```
wait!(sim::Clock, cond::Union{SimExpr, Array, Tuple}; scope::Module=Main)
wait!(cond::Union{SimExpr, Array, Tuple}; scope::Module=Main)
```
Wait on a clock for a condition to become true. Suspend the calling process
until the given condition is true.

# Arguments
- `sim::Clock`: clock, if no clock is given, the delay goes to `𝐶`.
- `cond::Union{SimExpr, Array, Tuple}`: a condition is an expression or SimFunction
    or an array or tuple of them. It is true if all expressions or SimFunctions
    therein return true.
- `scope::Module=Main`: evaluation scope for given expressions
"""
function wait!(sim::Clock, cond::Union{SimExpr, Array, Tuple}; scope::Module=Main)
    if all(simExec(sconvert(cond)))   # all conditions met
        return         # return immediately
    else
        c = Channel(0)
        event!(sim, SimFunction(put!, c, 1), cond, scope=scope)
        take!(c)
    end
end
wait!(cond::Union{SimExpr, Array, Tuple}; scope::Module=Main) = wait!(𝐶, cond, scope=scope)

"start all registered processes."
function step!(sim::Clock, ::Idle, ::Start)
    for p ∈ values(sim.processes)
        startup!(p)
    end
end

"""
    start!(sim::Clock)

Start all registered processes in a clock.
"""
start!(sim::Clock) = step!(sim, sim.state, Start())

"""
    stop!(p::SimProcess, ev::SEvent, value=nothing)

Stop a `SimProcess` by throwing a `SimException` to it.
"""
function stop!(p::SimProcess, ev::SEvent, value=nothing)
    schedule(p.task, SimException(ev, value), error=true)
    yield()
end
