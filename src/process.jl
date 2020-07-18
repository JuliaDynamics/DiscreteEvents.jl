#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
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
# - `cycles=Inf`: determine, how often the loop should be run.
function _loop(p::Prc, cycles::T) where {T<:Number}
    if threadid() > 1 && !isempty(p.clk.ac)
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
function _startup!(c::C, p::Prc, cycles::T, spawn::Bool) where {C<:AbstractClock,T<:Number}

    function startit()
        p.task = @task _loop(p, cycles)
        yield(p.task)
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
    process!([clk], prc, cycles; spawn)

Register a [`Prc`](@ref) to a clock, start it as an asynchronous process and
return the `id` it was registered with. It can then be found under `clk.processes[id]`.

# Arguments
- `c<:AbstractClock`: if not provided, the process runs under `𝐶`,
- `prc::Prc`: it contains a function and its arguments,
- `cycles<:Number=Inf`: number of cycles the process should run,
- `spawn::Bool=false`: if true, the process may be scheduled on another thread
    in parallel and registered to the thread specific clock.

!!! note
    `spawn`ing a process is possible only with parallel clocks setup with
    [`PClock`](@ref) or [`fork!`](@ref).
"""
function process!(c::C, p::Prc, cycles::T=Inf; spawn::Bool=false) where {C<:AbstractClock,T<:Number}
    p.clk = c
    _startup!(c, p, cycles, spawn)
    p.id
end
process!(p::Prc, cycles::T=Inf) where {T<:Number} = process!(𝐶, p, cycles)

# wakeup a process waiting for a `Condition`
_wakeup(c::Condition) = (notify(c); yield())

"""
```
delay!(clk, Δt)
delay!(clk, T, t)
```
Delay (suspend) a process for a time interval `Δt` on the clock `clk`.

# Arguments
- `Δt<:Number`: time interval,
- `T::Timing`: only `until` is accepted,
- `t<:Number`: delay until time t if t > clk.time, else give a warning.
"""
function delay!(clk::Clock, Δt::N) where {N<:Number}
    c = Condition()
    event!(clk, ()->_wakeup(c), after, Δt)
    wait(c)
end
function delay!(clk::Clock, T::Timing, t::N) where {N<:Number}
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
    wait!(clk, cond)

Delay (suspend) a process on a clock clk until a condition has become true.

# Arguments
- `cond<:Action`: a condition is is true if all expressions or functions therein return true.
"""
function wait!(clk::Clock, cond::A) where {A<:Action}
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
function interrupt!(p::Prc, ev::EV, value=nothing) where {EV<:ClockEvent}
    schedule(p.task, ClockException(ev, value), error=true)
    yield()
end

"Stop a Prc"
stop!(p::Prc, value=nothing) = interrupt!(p, Stop(), value)

"""
    now!(clk::Clock, ex::A) where {A<:Action}

Tell the clock to execute an IO-operation ex and not to proceed before ex is finished.
"""
now!(clk::Clock, ex::A) where {A<:Action} = event!(clk, ex, clk.time)
