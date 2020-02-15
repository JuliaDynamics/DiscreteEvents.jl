#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

# @static if VERSION >= v"1.3"
#     using Base.Threads: @spawn
# else
#     @eval const $(Symbol("@spawn")) = $(Symbol("@async"))
# end

# Register a Prc to a clock. Check its id and change it apropriately.
function _register!(clk::Clock, p::Prc)
    id = p.id
    while haskey(clk.processes, id)
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
    clk.processes[id] = p
    p.id = id
end

# Put a [`Prc`](@ref) in a loop which can be broken by a `ClockException`.
# - `p::Prc`:
# - `start::Channel`: a channel to ensure that a process starts,
# - `cycles=Inf`: determine, how often the loop should be run.
function _loop(p::Prc, start::Channel, cycles::Number)
    take!(start)
    if threadid() > 1
        p.clk = pclock(p.clk, threadid())
    end

    while cycles > 0
        try
            p.f(p.clk, p.arg...; p.kw...)
        catch exc
            if isa(exc, ClockException)
                exc.ev == Stop() && break
            end
            rethrow(exc)
        end
        cycles -= 1
    end
    p.clk.processes = delete!(p.clk.processes, p.id)
end

# startup a `Prc` as a task in a loop.
function _startup!(c::AbstractClock, p::Prc, cycles::Number, spawn::Bool)

    function startit()
        start = Channel{Int}(0)
        p.task = @async _loop(p, start, cycles)
        put!(start, 1)  # block until the process has started
    end

    if spawn
        if threadid() == 1
            @assert !isempty(c.ac) "no parallel clocks available!"
            sid = spawnid(c)
            if sid == 1
                startit()
            else
                talk(c, sid, Register((p=p, cycles=cycles)) )
            end
        else
            @threads for i in 1:nthreads()
                if threadid() == 1
                    process!(c.master[], p, cycles, spawn=spawn)
                end
            end
        end
    else
        startit()
    end
    _register!(p.clk, p)
end

"""
```
process!([clk::Clock], p::Prc, cycles=Inf; spawn::Bool=false)
```
Register a [`Prc`](@ref) to a clock, start it as an asynchronous process and
return the `id` it was registered with. It can then be found under `clk.processes[id]`.

# Arguments
- `c::AbstractClock`: `Clock` or `ActiveClock`, if not provided, the process runs
    under `𝐶`,
- `p::Prc`: it contains a function and its arguments,
- `cycles::Number=Inf`: number of cycles the process should run,
- `spawn::Bool=false`: if true, the process may be scheduled on another thread
    in parallel and registered to the thread specific clock.

!!! note
    `spawn`ing a process is possible only with parallel clocks setup with
    [`PClock`](@ref) or [`fork!`](@ref).

"""
function process!(c::AbstractClock, p::Prc, cycles::Number=Inf; spawn::Bool=false)
    p.clk = c
    _startup!(c, p, cycles, spawn)
    p.id
end
process!(p::Prc, cycles=Inf) = process!(𝐶, p, cycles)

# wakeup a process waiting for a `Condition`
_wakeup(c::Condition) = (notify(c); yield())

"""
```
delay!(clk::Clock, t::Number)
```
Delay a process for a time interval `t` on the clock `clk`. Suspend the calling
process until being reactivated by the clock at the appropriate time.

# Arguments
- `clk::Clock`: if not provided, the delay goes to `𝐶`.
- `t::Number`: the time interval for the delay.
"""
function delay!(clk::Clock, t::Number)
    c = Condition()
    event!(clk, ()->_wakeup(c), after, t)
    wait(c)
end

"""
```
delay!(clk::Clock, T::Timing, t::Number)
```

Used for delaying a process *until* a given time t.

# Arguments
- `clk::Clock`: if no clock is given, the delay goes to 𝐶,
- `T::Timing`: only `until` is accepted,
- `t::Number`: delay until time t if t > clk.time, else give a warning.
"""
function delay!(clk::Clock, T::Timing, t::Number)
    @assert T == until "bad Timing $T for delay!"
    if t > clk.time
        c = Condition()
        event!(clk, ()->_wakeup(c), t)
        wait(c)
    else
        now!(clk, fun(println, stderr, "warning: delay until $t ≤ τ=$(tau(clk))"))
    end
end

"""
```
wait!(clk::Clock, cond::Action)
```
Wait on a clock for a condition to become true. Suspend the calling process
until the given condition is true.

# Arguments
- `clk::Clock`: if no clock is supplied, the delay goes to `𝐶`,
- `cond::Action`: a condition is an expression or function
    or an array or tuple of them. It is true only if all expressions or functions
    therein return true,
"""
function wait!(clk::Clock, cond::Action)
    if all(_evaluate(cond))   # all conditions met
        return         # return immediately
    else
        c = Condition()
        event!(clk, ()->_wakeup(c), cond)
        wait(c)
    end
end

"""
    interrupt!(p::Prc, ev::ClockEvent, value=nothing)

Interrupt a `Prc` by throwing a `ClockException` to it.
"""
function interrupt!(p::Prc, ev::ClockEvent, value=nothing)
    schedule(p.task, ClockException(ev, value), error=true)
    yield()
end

"Stop a Prc"
stop!(p::Prc, value=nothing) = interrupt!(p, Stop(), value)

"""
```
now!(clk::Clock, op::Action)
```
Tell the clock to execute an operation. Thus it cannot proceed before the op is finished.

!!! note
    This is needed for IO-operations of tasks. IO-operations yield the task to
    the scheduler and the scheduler may invoke the clock before giving control
    back to the task. In that case the clock will proceed and the task has gone
    out of sync with the clock. Use `now!` to avoid this situation!

# Arguments
- `clk::Clock`,
- `op::Action`: operation to execute.
"""
now!(clk::Clock, ex::Action) = event!(clk, ex, clk.time)
