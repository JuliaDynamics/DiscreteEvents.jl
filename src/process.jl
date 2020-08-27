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
    threadid() > 1 && (p.clk = pclock(p.clk).clock)
    _register!(p.clk, p)
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
function _startup!(c::C, p::Prc, cycles::T, cid::Int, spawn::Bool) where {C<:AbstractClock,T<:Number}

    function startit()
        p.task = @task _loop(p, cycles)
        yield(p.task)
        return p.task
    end

    t = Task(nothing)
    cid = _cid(c, cid, spawn)
    if cid == c.id
        t = startit()
    else
        @threads for i in 1:nthreads()
            i == cid && (t = startit())
        end
    end
    return t
end

"""
    process!([clk], prc, cycles; <keyword arguments>)

Register a [`Prc`](@ref) to a clock, start an asynchronous task 
executing the process function in a loop and return the `id` it 
was registered with. It can then be found under `clk.processes[id]`.

# Arguments
- `c<:AbstractClock`: if not provided, the process runs under `𝐶`,
- `prc::Prc`: it contains a function and its arguments,
- `cycles<:Number=Inf`: number of loop cycles the process should run,

# Keyword arguments
- `cid::Int=clk.id`: if cid ≠ clk.id, assign the event to the parallel clock
    with id == cid. This overrides `spawn`,
- `spawn::Bool=false`: if true, the process may be scheduled on another thread
    in parallel and registered to the thread specific clock.
"""
function process!(c::C, p::Prc, cycles::T=Inf; 
                  cid::Int=c.id, spawn::Bool=false) where {C<:AbstractClock,T<:Number}
    p.clk = c
    t = _startup!(c, p, cycles, cid, spawn)
    istaskfailed(t) && return t
    p.id
end
process!(p::Prc, cycles::T=Inf; kwargs...) where {T<:Number} = process!(𝐶, p, cycles; kwargs...)

# wakeup a process waiting for a `Condition`
# two yields for giving back control first and then enabling a
# take! on a channel (heuristic solution of the clock overrun problem)
_wakeup(c::Condition) = (notify(c); yield(); yield())

"""
```
delay!(clk, Δt)
delay!(clk, T, t)
```
Delay (suspend) a process for a time interval `Δt` on the clock `clk`.

# Arguments
- `clk::Clock`,
- `Δt`: time interval, `Number` or `Distribution`,
- `T::Timing`: only `until` is accepted,
- `t`: time delay, `Number` or `Distribution`.
"""
function delay!(clk::Clock, Δt::N) where N<:Number
    c = Condition()
    event!(clk, ()->_wakeup(c), after, Δt)
    wait(c)
end
function delay!(clk::Clock, T::Timing, t::N) where N<:Number
    @assert T == until "bad Timing $T for delay!"
    if t > clk.time
        c = Condition()
        event!(clk, ()->_wakeup(c), t)
        wait(c)
    else
        now!(clk, fun(println, stderr, "warning: delay until $t ≤ τ=$(tau(clk))"))
    end
end
delay!(clk::Clock, Δt::X) where X<:Distribution = delay!(clk, rand(Δt))
delay!(clk::Clock, T::Timing, t::X) where X<:Distribution = delay!(clk, T, rand(t))

"""
    wait!(clk, cond)

Delay (suspend) a process on a clock clk until a condition has become true.

# Arguments
- `clk::Clock`,
- `cond<:Action`: a condition, true if all expressions or functions therein return true.
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

Transfer an IO-operation `ex` to the master clock (on thread 1). 
The clock executes it before proceeding to the next time step.
"""
now!(clk::Clock, ex::A) where {A<:Action} = event!(clk, ex, clk.time, cid=1)

"""
```
print(clk::Clock, [io::IO], x, xs...)
```
Create a [`now!`](@ref) event to a busy clock `clk` to `print(x, xs...)` 
to `io` (or to `stdout`).

If the clock is not busy, `x` and `xs...` are printed as usual.
`print(clk)` still prints `repr(clk)`.
"""
function Base.print(clk::Clock, io::IO, x, xs...)
    if clk.state == Busy()
        now!(clk, fun(print, io, x))
        for x_ in xs
            now!(clk, fun(print, io, x_))
        end
    else
        print(io, x, xs...)
    end
end
Base.print(clk::Clock, x, xs...) = print(clk, stdout, x, xs...)

"""
```
println(clk::Clock, [io::IO], xs...)
```
Create a [`now!`](@ref) event to a busy clock `clk` to `println(x, xs...)` 
to `io` (or to `stdout`).

If the clock is not busy, `x` and `xs...` are printed as usual.
`println(clk)` still prints `repr(clk)`.
"""
Base.println(clk::Clock, io::IO, x, xs...) = print(clk, io, x, xs..., '\n')
Base.println(clk::Clock, x, xs...) = print(clk, x, xs..., '\n')
