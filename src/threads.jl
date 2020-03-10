#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

const _handle_exceptions = [true]

# ---------------------------------------------------------
# methods for active clocks
# ---------------------------------------------------------
tau(ac::ActiveClock) = tau(ac.clock)
_busy(ac::ActiveClock) = ac.clock.state == Busy()
sync!(ac::ActiveClock, clk::Clock) = sync!(ac.clock, clk)

delay!(ac::ActiveClock, args...) = delay!(ac.clock, args...)
wait!(ac::ActiveClock, args...; kwargs...) = wait!(ac.clock, args...; kwargs...)
now!(ac::ActiveClock, ex::A) where {A<:Action} = now!(ac.clock, ex)


# ---------------------------------------------------------
# state machine operations of active clocks
# ---------------------------------------------------------
step!(A::ActiveClock, ::Idle, ::Start) = ( A.clock.evcount = 0; A.clock.scount = 0)

function step!(A::ActiveClock, ::Idle, σ::Run)
    t0 = time_ns()
    _cycle!(A.clock, σ.duration, σ.sync)
    put!(A.back, Done(time_ns()-t0))
end

function step!(A::ActiveClock, ::Idle, σ::Finish)
    _finish!(A.clock, σ.tend)
    put!(A.back, Response((A.clock.evcount, A.clock.scount)))
end

step!(A::ActiveClock, ::Union{Idle, Busy}, ::Sync) = nothing

step!(A::ActiveClock, ::ClockState, ::Query) = put!(A.back, Response(A))

step!(A::ActiveClock, ::Union{Idle, Busy}, σ::Register) = _assign(A, σ.x, A.id)

function step!(A::ActiveClock, ::Union{Idle, Busy}, σ::Reset)
    m = A.master[]
    reset!(A.clock, m.Δt, t0=m.time, hard=σ.type, unit=m.unit)
    put!(A.back, Response(1))
end

step!(A::ActiveClock, q::ClockState, σ::ClockEvent) = error("transition q=$q, σ=$σ not implemented")

# -------------------------------------
# event loop for an active clock.
# -------------------------------------
function _activeClock(cmd::Channel, resp::Channel)
    info = take!(cmd) # get a pointer to the master clock and id
    ac = ActiveClock(Clock(), info.m, cmd, resp, info.id, threadid())
    ac.clock.id = info.id
    sf = Array{Base.StackTraces.StackFrame,1}[]
    exc = nothing
    ac.clock.state = Idle()
    sync!(ac.clock, ac.master[])

    while true
        σ = take!(cmd)
        if σ isa Stop
            break
        elseif σ isa Diag
            put!(resp, Response((exc, sf)))
        elseif _handle_exceptions[end]
            try
                step!(ac, ac.clock.state, σ)
            catch exc
                sf = stacktrace(catch_backtrace())
                @warn "clock $(ac.id), thread $(ac.thread) exception: $exc"
                put!(resp, Error(exc))  # send error to avoid master hangs
            end
        else
            step!(ac, ac.clock.state, σ)
        end
    end
    # stop task
    # close channel
end


# ---------------------------------------------------------
# starting and destroying active clocks
# ---------------------------------------------------------

# Start a task on each available thread (other than 1).
# - `f::Function`: function to start, has to take two channels as arguments,
# - `ch_size=256`: channel capacity for event transfer between clocks during
#                  each time step.
function _start_threads(f::F, ch_size=256)::Vector{ClockChannel} where {F<:Function}
    ac = ClockChannel[]
    for i in 1:nthreads()
        if i > 1
            ai = ClockChannel(Ref{Task}(),
                    Channel{ClockEvent}(ch_size),
                    Channel{ClockEvent}(ch_size),
                    i, false, 0)
            push!(ac, ai)
        end
    end
    @threads for i in 1:nthreads()
        i > 1 && (ai = ac[i-1]; ai.ref = Ref(@async f(ai.forth, ai.back)))
    end
    return ac
end

"""
    fork!(master::Clock)

Establish copies of a clock on all parallel threads and operate them as active
clocks under control of the master clock.

# Arguments
- `master::Clock`: the master clock, must be on thread 1
"""
function fork!(master::Clock)
    if (master.id == 0) && (threadid() == 1)
        if VERSION >= v"1.3"
            if nthreads() > 1
                if isempty(master.ac)
                    master.ac = _start_threads(_activeClock)           # startup steps
                    for i in eachindex(master.ac)                    # to all active clocks …
                        put!(master.ac[i].forth, Startup(Ref(master), i)) # send pointer and id
                    end
                else
                    println(stderr, "clock already has $(length(clk.ac)) active clocks!")
                end
            else
                println(stderr, "no parallel threads available!")
            end
        else
            println(stderr, "you have Julia $VERSION, threading is available for ≥ 1.3!")
        end
    else
        println(stderr, "only the master clock on thread 1 can be multiplied!")
    end
end

"""
    collapse!(master::Clock)

Transfer the schedules of the parallel clocks to master and them stop them.

!!! note
    If there are processes on other threads registered to parallel clocks,
    make sure that they aren't needed anymore before calling `collapse`. They
    are not transferred to and cannot be controlled by master.
"""
function collapse!(master::Clock)
    if (master.id == 0) && (threadid() == 1)
        for ac in master.ac
            put!(ac.forth, Query())
            c = take!(ac.back).x.clock
            for (ev, t) in pairs(c.sc.events)    # transfer events to master
                while any(i->i==t, values(master.sc.events)) # in case an event at that time exists
                    t = nextfloat(float(t))                  # increment scheduled time
                end
                master.sc.events[ev] = t
            end
            append!(master.sc.cevents, c.sc.cevents)
            append!(master.sc.samples, c.sc.samples)
            put!(ac.forth, Stop())
        end
        empty!(master.ac)
    else
        println(stderr, "only the master clock on thread 1 can be collapsed!")
    end
end

"""
    PClock(Δt::T=0.01; t0::U=0, unit::FreeUnits=NoUnits) where {T<:Number,U<:Number}

Setup a clock with parallel clocks on all available threads.

# Arguments

- `Δt::T=0.01`: time increment. For parallel clocks Δt has to be > 0.
    If given Δt ≤ 0 it is set to 0.01.
- `t0::U=0`: start time for simulation
- `unit::FreeUnits=NoUnits`: clock time unit. Units can be set explicitely by
    setting e.g. `unit=minute` or implicitly by giving Δt as a time or else setting
    t0 to a time, e.g. `t0=60s`.

!!! note
    Processes on multiple threads are possible in Julia ≥ 1.3 and with
    [`JULIA_NUM_THREADS > 1`](https://docs.julialang.org/en/v1/manual/environment-variables/#JULIA_NUM_THREADS-1).
"""
function PClock(Δt::T=0.01; t0::U=0, unit::FreeUnits=NoUnits) where {T<:Number,U<:Number}
    Δt = Δt > 0 ? Δt : 0.01
    clk = Clock(Δt, t0=t0, unit=unit)
    fork!(clk)
    return clk
end

# ---------------------------------------------------------
# control of active clocks
# ---------------------------------------------------------
"""
```
pclock(clk::Clock, id::Int ) :: AbstractClock
pclock(ac::ActiveClock, id::Int ) :: AbstractClock
```
Get a parallel clock to a given clock.

# Arguments
- `master::Clock`: a master clock or
- `ac::ActiveClock`: an active clock,
- `id::Int=threadid()`: thread id, defaults to the caller's current thread.

# Returns
- the master `Clock` if id==0,
- a parallel `ActiveClock` else
"""
function pclock(clk::Clock, id::Int) :: AbstractClock
    if id == 0
        @assert clk.id == 0 "you cannot get master from a local clock!"
        return clk
    elseif id in eachindex(clk.ac)
        put!(clk.ac[id].forth, Query())
        return take!(clk.ac[id].back).x
    else
        println(stderr, "parallel clock $id not available!")
    end
end
function pclock(ac::ActiveClock, id::Int) :: AbstractClock
    if id == ac.clock.id
        return ac
    else
        return pclock(ac.master[], id)
    end
end

"""
    diagnose(clk::Clock, id::Int)

Return the stacktrace from a parallel clock.

# Arguments
- `clk::Clock`: a master clock,
- `id::Int`: the id of a parallel clock.
"""
function diagnose(clk::Clock, id::Int)
    if id in eachindex(clk.ac)
        if istaskfailed(clk.ac[id].ref[])
            return clk.ac[id].ref[]
        else
            while isready(clk.ac[id].back)
                msg = take!(clk.ac[id].back)
                println(msg)
            end
            put!(clk.ac[id].forth, Diag())
            return take!(clk.ac[id].back).x
        end
    else
        println(stderr, "parallel clock $id not available!")
    end
end

"""
    onthread(f::F, id::Int) where {F<:Function}

Execute a function f on thread id.

Single-threaded simulations involving processes speed up a lot when
they are run on a thread other than 1. Thus they must not compete
against background tasks.

# Examples, usage

```julia
julia> using DiscreteEvents, .Threads

julia> onthread(threadid, 2)
2

julia> onthread(3) do; threadid(); end
3

julia> onthread(4) do
           threadid()
       end
4
```
"""
function onthread(f::F, id::Int) where {F<:Function}
    t = Task(nothing)
    @assert id in 1:nthreads() "thread $id not available!"
    @threads for i in 1:nthreads()
        if i == id
            t = @async f()
        end
    end
    fetch(t)
end
