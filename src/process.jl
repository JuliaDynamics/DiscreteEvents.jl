#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#


"""
    loop(p::SimProcess, start::Channel, cycles::Number)

Put a `SimProcess` in a loop, which can be broken by a `SimException`.

# Arguments
- `p::SimProcess`:
- `start::Channel`: a channel to ensure that a process starts,
- `cycles=Inf`: determine, how often the loop should be run.
"""
function loop(p::SimProcess, start::Channel, cycles::Number)
    take!(start)
    while cycles > 0
        try
            p.func(p.arg...; p.kw...)
        catch exc
            if isa(exc, SimException)
                exc.ev == Stop() && break
            end
            rethrow(exc)
        end
        cycles -= 1
    end
    p.sim.processes = delete!(p.sim.processes, p.id)
end

"""
    startup!(p::SimProcess, cycles::Number)

Start a `SimProcess` as a task in a loop.
"""
function startup!(p::SimProcess, cycles::Number)
    start = Channel{Int}(0)
    p.task = @async loop(p, start, cycles)
    p.state = Idle()
    put!(start, 1) # let the process start
end

"""
```
process!([sim::Clock], p::SimProcess, cycles=Inf)
```
Register a [`SimProcess`](@ref) to a clock, start it as an asynchronous process and
return the `id` it was registered with. It can then be found under `sim.processes[id]`.

# Arguments
- `sim::Clock`: if not provided, the process runs under 𝐶,
- `p::SimProcess`: it contains a function and its arguments,
- `cycles::Number=Inf`: number of cycles the process should run.
"""
function process!(sim::Clock, p::SimProcess, cycles::Number=Inf)
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
    p.sim = sim
    startup!(p, cycles)
    id
end
process!(p::SimProcess, cycles=Inf) = process!(𝐶, p, cycles)

"wakeup a process waiting for a `Condition`"
wakeup(c::Condition) = (notify(c), yield())

"""
```
delay!([sim::Clock], t::Number)
```
Delay a process for a time interval `t` on the clock `sim`. Suspend the calling
process until being reactivated by the clock at the appropriate time.

# Arguments
- `sim::Clock`: if not provided, the delay goes to `𝐶`.
- `t::Number`: the time interval for the delay.
"""
function delay!(sim::Clock, t::Number)
    c = Condition()
    event!(sim, SF(wakeup, c), after, t)
    wait(c)
end
delay!(t::Number) = delay!(𝐶, t)

"""
```
delay!([sim::Clock], T::Timing, t::Number)
```

Used for delaying a process *until* a given time t.

# Arguments
- `sim::Clock`: if no clock is given, the delay goes to 𝐶,
- `T::Timing`: only `until` is accepted,
- `t::Number`: delay until time t if t > sim.time, else give a warning.
"""
function delay!(sim::Clock, T::Timing, t::Number)
    @assert T == until "bad Timing $T for delay!"
    if t > sim.time
        c = Condition()
        event!(sim, SF(wakeup, c), t)
        wait(c)
    else
        now!(sim, SF(println, stderr, "warning: delay until $t ≤ τ=$(tau(sim))"))
    end
end
delay!(T::Timing, t::Number) = delay!(𝐶, T, t)

"""
```
wait!([sim::Clock], cond::Union{SimExpr, Array, Tuple}; scope::Module=Main)
```
Wait on a clock for a condition to become true. Suspend the calling process
until the given condition is true.

# Arguments
- `sim::Clock`: if no clock is supplied, the delay goes to `𝐶`,
- `cond::Union{SimExpr, Array, Tuple}`: a condition is an expression or SimFunction
    or an array or tuple of them. It is true only if all expressions or SimFunctions
    therein return true,
- `scope::Module=Main`: evaluation scope for given expressions.
"""
function wait!(sim::Clock, cond::Union{SimExpr, Array, Tuple}; scope::Module=Main)
    if all(simExec(sconvert(cond)))   # all conditions met
        return         # return immediately
    else
        c = Condition()
        event!(sim, SF(wakeup, c), cond, scope=scope)
        wait(c)
    end
end
wait!(cond::Union{SimExpr, Array, Tuple}; scope::Module=Main) = wait!(𝐶, cond, scope=scope)

"""
    interrupt!(p::SimProcess, ev::SEvent, value=nothing)

Interrupt a `SimProcess` by throwing a `SimException` to it.
"""
function interrupt!(p::SimProcess, ev::SEvent, value=nothing)
    schedule(p.task, SimException(ev, value), error=true)
    yield()
end

"Stop a SimProcess"
stop!(p::SimProcess, value=nothing) = interrupt!(p, Stop(), value)

"""
```
now!([sim::Clock], op::Union{SimExpr, Array, Tuple})
```
Let the given operation be executed now by the clock. Thus the clock cannot proceed
before the op is finished.

# Arguments
- `sim::Clock`: if not provided, the operation is executed by 𝐶 (must be running),
- `op::Union{SimExpr, Array, Tuple}`: operation to execute.
"""
now!(sim::Clock, ex::Union{SimExpr, Array, Tuple}) = event!(sim, ex, sim.time)
now!(ex::Union{SimExpr, Array, Tuple}) = now!(𝐶, ex)
