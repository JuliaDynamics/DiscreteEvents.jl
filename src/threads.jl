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
sync!(ac::ActiveClock, clk::Clock) = sync!(ac.clock, clk)

event!(ac::ActiveClock, ex::Union{SimExpr, Tuple, Vector}, t::Number;
       scope::Module=Main, cycle::Number=0.0) = event!(ac.clock, ex, t, scope=scope, cycle=cycle)
event!(ac::ActiveClock, ex::Union{SimExpr, Tuple, Vector}, T::Timing, t::Number;
       scope::Module=Main) = event!(ac.clock, ex, T, t, scope=scope)
event!(ac::ActiveClock, ex::Union{SimExpr, Tuple, Vector}, cond::Union{SimExpr, Tuple, Vector};
       scope::Module=Main) = event!(ac.clock, ex, cond, scope = scope)
sample!(ac::ActiveClock, ex::Union{Expr, SimFunction}, Δt::Number=ac.clock.Δt;
       scope::Module=Main) = sample!(ac.clock, ex, Δt, scope=scope)

delay!(ac::ActiveClock, t::Number) = delay!(ac.clock, t)
delay!(ac::ActiveClock, T::Timing, t::Number) = delay!(ac.clock, T, t)
wait!(ac::ActiveClock, cond::Union{SimExpr, Array, Tuple}; scope::Module=Main) =
      wait!(ac.clock, cond, scope=scope)
now!(ac::ActiveClock, ex::Union{SimExpr, Array, Tuple}) = now!(ac.clock, ex)


# ---------------------------------------------------------
# state machine operations of active clocks
# ---------------------------------------------------------
"Run an active clock for a given duration."
step!(A::ActiveClock, ::Idle, σ::Run) = do_run!(A.clock, σ.duration)

function step!(A::ActiveClock, ::Union{Idle, Busy}, σ::Sync)
end

step!(A::ActiveClock, ::SState, ::Query) = A

function step!(A::ActiveClock, ::Union{Idle, Busy}, σ::Register)
    if σ.x isa SimEvent
        return event!(A, σ.x.ex, σ.x.t, scope=σ.x.scope, cycle=σ.x.Δt)
    elseif σ.x isa SimCond
        return event!(A, σ.x.ex, σ.x.cond, scope=σ.x.scope)
    elseif σ.x isa Sample
        return sample!(A, σ.x.ex, A.clock.Δt, scope=σ.x.scope)
    elseif σ.x isa SimProcess
        return process!(A, σ.x.p, σ.x.cycles)
    else
        nothing
    end
end

function step!(A::ActiveClock, ::Union{Idle, Busy}, σ::Reset)
end

step!(A::ActiveClock, q::SState, σ::SEvent) = error("transition q=$q, σ=$σ not implemented")

"""
    activeClock(ch::Channel)

Operate an active clock on a given channel. This is its event loop.
"""
function activeClock(ch::Channel)
    ac = ActiveClock(Clock(),        # create an active clock, for it …
                     take!(ch), ch)  # get a pointer to the master clock
    sf = Array{Base.StackTraces.StackFrame,1}[]
    ac.clock.state = Idle()
    sync!(ac.clock, ac.master[])

    while true
        try
            σ = take!(ch)
            if σ isa Stop
                break
            elseif σ isa Diag
                put!(ch, Response(sf))
            else
                put!(ch, Response(step!(ac, ac.clock.state, σ)))
            end
        catch exp
            sf = stacktrace()
            println("clock $(threadid()) exception: $exp")
            put!(ch, Response(exp))
            # throw(exp)
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
- `f::Function`: function to start, has to take a channel as its only argument,
- `mul::Int=3`: startup multiplication factor,
"""
function start_threads(f::Function) :: Vector{AC}
    ac = AC[]
    @threads for i in 1:nthreads()
        if threadid() > 1
            ai = AC(Ref{Task}(), Channel(), threadid())
            ai.ref = Ref(@async f(ai.ch))
            push!(ac, ai)
        end
    end
    sort!(ac, by = x->x.id)
    println("got $(length(ac)) threads parallel to master!")
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
    if (master.id == 1) && (threadid() == 1)
        if VERSION >= v"1.3"
            if nthreads() > 1
                if isempty(master.ac)
                    master.ac = start_threads(activeClock) # startup steps
                    for ac in master.ac                    # to all active clocks …
                        put!(ac.ch, Ref(master))           # send pointer to master
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
    if (master.id == 1) && (threadid() == 1)
        for ac in master.ac
            put!(ac.ch, Query())
            c = take!(ac.ch).x.clock
            for (ev, t) in pairs(c.sc.events)    # transfer events to master
                while any(i->i==t, values(master.sc.events)) # in case an event at that time exists
                    t = nextfloat(float(t))                  # increment scheduled time
                end
                master.sc.events[ev] = t
            end
            append!(master.sc.cevents, c.sc.events)
            append!(master.sc.samples, c.sc.samples)
            put!(ac.ch, Stop())
        end
        empty!(master.ac)
    else
        println(stderr, "only the master clock on thread 1 can be collapsed!")
    end
end


# ---------------------------------------------------------
# control of active clocks
# ---------------------------------------------------------
"""
    talk(master::Clock, id::Int, σ::SEvent) :: Response

Talk with a parallel clock: send an event σ and get the response. This is for
user interaction with a parallel clock. It blocks until it has finished.

# Arguments
- `master::Clock`: a master clock,
- `id::Int`: threadid of the active clock,
- `σ::SEvent`: the event/command to send to the active clock.
"""
function talk(master::Clock, id::Int, σ::SEvent) :: Response
    @assert master.id == 1 "you can talk only through a master clock"
    cix = ((i.id for i in master.ac)...,)
    if id in cix
        ch = master.ac[findfirst(x->x==id, cix)].ch
        put!(ch, σ)
        return take!(ch)
    else
        return Response(id == 1 ? "id 1 is master" : "id $id not known")
    end
end

"""
```
pclock(clk::Clock, id::Int=threadid() ) :: AbstractClock
pclock(ac::ActiveClock, id::Int=threadid()) :: AbstractClock
```
Get a parallel clock to a given clock. If id is not provided, it returns
the clock for the current thread.

# Arguments
- `master::Clock`: a master clock or
- `ac::ActiveClock`: an active clock,
- `id::Int=threadid()`: thread id, defaults to the caller's current thread.

# Returns
- the master `Clock` if id==1,
- a parallel `ActiveClock` else
"""
function pclock(clk::Clock, id::Int=threadid() ) :: AbstractClock
    if id == 1
        return clk
    elseif id in ((i.id for i in clk.ac)...,)
        return talk(clk, id, Query()).x
    else
        println(stderr, "parallel clock on thread $id not available!")
    end
end
function pclock(ac::ActiveClock, id::Int=threadid()) :: AbstractClock
    if id == ac.clock.id
        return ac
    else
        return pclock(ac.master[], id)
    end
end

"""
    spawnid(clk::Clock) :: Int

Return a random number out of the thread ids of all available parallel clocks.
This is used for `spawn`ing tasks or events to them.

!!! note
    This function may be used for workload balancing between threads
    in the future.
"""
function spawnid(clk::Clock) :: Int
    if clk.id > 1
        println(stderr, "spawn works only from a master clock")
        return clk.id
    elseif isempty(clk.ac)
        return 1
    else
        return rand(rng, (1, (i.id for i in clk.ac)...))
    end
end
