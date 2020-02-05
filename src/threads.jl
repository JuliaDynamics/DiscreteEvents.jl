#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

# ---------------------------------------------------------
# methods for active clocks
# ---------------------------------------------------------
tau(ac::ActiveClock) = tau(ac.clock)
busy(ac::ActiveClock) = ac.clock.state == Busy()
sync!(ac::ActiveClock, clk::Clock) = sync!(ac.clock, clk)

delay!(ac::ActiveClock, args...) = delay!(ac.clock, args...)
wait!(ac::ActiveClock, args...; kwargs...) = wait!(ac.clock, args...; kwargs...)
now!(ac::ActiveClock, ex::Action) = now!(ac.clock, ex)


# ---------------------------------------------------------
# state machine operations of active clocks
# ---------------------------------------------------------
"Run an active clock for a given duration."
step!(A::ActiveClock, ::Idle, σ::Run) = do_run!(A.clock, σ.duration)

step!(A::ActiveClock, ::Union{Idle, Busy}, ::Sync) = nothing

step!(A::ActiveClock, ::ClockState, ::Query) = put!(A.back, Response(A))

step!(A::ActiveClock, ::Union{Idle, Busy}, σ::Register) = assign(A, σ.x, A.id)

step!(A::ActiveClock, ::Union{Idle, Busy}, ::Reset) = nothing

step!(A::ActiveClock, q::ClockState, σ::ClockEvent) = error("transition q=$q, σ=$σ not implemented")

"""
    activeClock(ch::Channel)

Operate an active clock on a given channel. This is its event loop.
"""
function activeClock(cmd::Channel, ans::Channel)
    info = take!(cmd).x # get a pointer to the master clock and id
    ac = ActiveClock(Clock(), info[1], cmd, ans, info[2], threadid())
    ac.clock.id = info[2]
    sf = Array{Base.StackTraces.StackFrame,1}[]
    exp = nothing
    ac.clock.state = Idle()
    sync!(ac.clock, ac.master[])

    while true
        try
            σ = take!(cmd)
            if σ isa Stop
                break
            elseif σ isa Diag
                put!(ans, Response((exp, sf)))
            else
                step!(ac, ac.clock.state, σ)
            end
        catch exp
            sf = stacktrace(catch_backtrace())
            @warn "clock $(ac.id), thread $(ac.thread) exception: $exp"
#            throw(exp)
        end
    end
    # stop task
    # close channel
end


# ---------------------------------------------------------
# starting and destroying active clocks
# ---------------------------------------------------------
"""
    start_threads(f::Function, mul::Int=3)

Start a task on each available thread (other than 1).

# Arguments
- `f::Function`: function to start, has to take two channels as arguments,
- `mul::Int=3`: startup multiplication factor,
"""
function start_threads(f::Function) :: Vector{ClockChannel}
    ac = ClockChannel[]
    @threads for i in 1:nthreads()
        if threadid() > 1
            ai = ClockChannel(Ref{Task}(), Channel{ClockEvent}(8), Channel{ClockEvent}(5),
                    threadid(), false)
            ai.ref = Ref(@async f(ai.forth, ai.back))
            push!(ac, ai)
        end
    end
    sort!(ac, by = x->x.thread)
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
                    master.ac = start_threads(activeClock)           # startup steps
                    for i in eachindex(master.ac)                    # to all active clocks …
                        put!(master.ac[i].forth, Start(( Ref(master), i) )) # send pointer and id
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
            append!(master.sc.cevents, c.sc.events)
            append!(master.sc.samples, c.sc.samples)
            put!(ac.forth, Stop())
        end
        empty!(master.ac)
    else
        println(stderr, "only the master clock on thread 1 can be collapsed!")
    end
end

"""
    PClock(Δt::Number=0.01; t0::Number=0, unit::FreeUnits=NoUnits)

Setup a clock with parallel clocks on all available threads.

# Arguments

- `Δt::Number=0.01`: time increment. For parallel clocks Δt has to be > 0.
    If given Δt ≤ 0 it is set to 0.01.
- `t0::Number=0`: start time for simulation
- `unit::FreeUnits=NoUnits`: clock time unit. Units can be set explicitely by
    setting e.g. `unit=minute` or implicitly by giving Δt as a time or else setting
    t0 to a time, e.g. `t0=60s`.

!!! note
    Processes on multiple threads are possible in Julia ≥ 1.3 and with
    [`JULIA_NUM_THREADS > 1`](https://docs.julialang.org/en/v1/manual/environment-variables/#JULIA_NUM_THREADS-1).
"""
function PClock(Δt::Number=0.01; t0::Number=0, unit::FreeUnits=NoUnits)
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
    diag(clk::Clock, id::Int)

Return the stacktrace from a parallel clock.

# Arguments
- `clk::Clock`: a master clock,
- `id::Int`: the id of a parallel clock.
"""
function diag(clk::Clock, id::Int)
    if id in eachindex(clk.ac)
        if istaskfailed(clk.ac[id].ref[])
            return clk.ac[id].ref[]
        else
            put!(clk.ac[id].forth, Diag())
            return take!(clk.ac[id].back).x
        end
    else
        println(stderr, "parallel clock $id not available!")
    end
end
