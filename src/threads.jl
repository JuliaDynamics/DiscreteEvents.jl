#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
export multiply!, pclock

"""
    ActiveClock

contains the thread specific data of an active clock.

# Fields
- `clock::Clock`: the thread local clock,
- `master::Ref{Clock}`: a pointer to the master clock, accessing it may be expensive,
- `ch::Channel`: the communication channel between the two.
"""
mutable struct ActiveClock <: Simulate.StateMachine
    clock::Clock
    master::Ref{Clock}
    ch::Channel
end

function step!(A::ActiveClock, ::Idle, σ::Run)
end

function step!(A::ActiveClock, ::Union{Idle, Busy}, σ::Sync)
end

step!(A::ActiveClock, ::SState, ::Query) = A.clock

function step!(A::ActiveClock, ::Union{Idle, Busy}, σ::Register)
    if σ.x isa SimEvent
        return event!(A.clock, σ.x.ex, σ.x.t, scope=σ.x.scope, cycle=σ.x.Δt)
    elseif σ.x isa SimCond
        return event!(A.clock, σ.x.ex, σ.x.cond, scope=σ.x.scope)
    elseif σ.x isa Sample
        return sample!(A.clock, σ.x.ex, A.clock.Δt, scope=σ.x.scope)
    else
        nothing
    end
end

function step!(A::ActiveClock, ::Union{Idle, Busy}, σ::Reset)
end

"""
    activeClock(ch::Channel)

Operate an active clock on a given channel.
"""
function activeClock(ch::Channel)
    ac = ActiveClock(Clock(),        # create an active clock, for it …
                     take!(ch), ch)  # 4. get a pointer to the master clock
    try
        ac.clock.state = Idle()
        sync!(ac.clock, ac.master[])

        while true
            σ = take!(ch)
            if σ isa Stop
                break
            else
                put!(ch, Response(step!(ac, ac.clock.state, σ)))
            end
        end
    catch exp
        println("clock $(threadid()) exception: $exp")
        throw(exp)
    end
    # stop task
    # close channel 
end

"Startup a task on a parallel thread."
function startup(ch::Channel)
    put!(ch, threadid())   # 1. send threadid
    if take!(ch) == true   # 2. get response, if true
        f = take!(ch)      # 3. get function
        f(ch)              #    and call it
    else                   # else let task finish
    end
end

"""
    start_threads(f::Function, mul::Int=3)

Start a function as a task on each available thread (other than 1).

# Arguments
- `f::Function`: function to start, has to take a channel as its only argument,
- `mul::Int=3`: startup multiplication factor,
"""
function start_threads(f::Function, mul::Int=3) :: Vector{AC}
    n = nthreads()                    #  how many threads are available
    thrd = AC[]
    ts = Vector{Int}()
    for i in 1:n*mul                  # n*mul trials
        th = AC(Ref{Task}(), Channel(), 0)
        th.ch = Channel(startup, taskref=th.ref, spawn=true)
        th.id = take!(th.ch)          # 1. get threadid
        push!(thrd, th)
    end

    ts = [t.id for t in thrd]         # threadids of all startup tasks spawned
    ix = indexin(2:n, ts)             # get first indices of available threads > 1
    ix = ix[ix .!= nothing]           # in case one could not established
    foreach(t->put!(t.ch, true), thrd[ix])   # 2. send true to only one task on each thread
    foreach(t->put!(t.ch, false), thrd[setdiff(1:n*mul,ix)]) # 2. send false to the rest
    thrd = thrd[ix]                   # keep only the established ones
    foreach(t->put!(t.ch, f), thrd)   # 3. sent them the function
    println("got $(length(thrd)) threads parallel to master!")
    return thrd
end

"""
    multiply!(master::Clock)

Establish copies of a clock on all parallel threads and operate them as active
clocks under control of the master clock.

# Arguments
- `master::Clock`: the master clock, must be on thread 1
"""
function multiply!(master::Clock)
    if (master.id == 1) && (threadid() == 1)
        if VERSION >= v"1.3"
            if nthreads() > 1
                if isempty(master.ac)
                    master.ac = start_threads(activeClock) # startup steps 1 - 3
                    for ac in master.ac                    # to all active clocks …
                        put!(ac.ch, Ref(master))           # 4. send pointers to master
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
    pclock(master::Clock, id::Int) :: Clock

Get a parallel clock from a master clock.

# Arguments
- `master::Clock`: a master clock.
- `id::Int`: threadid of the parallel clock.
"""
function pclock(master::Clock, id::Int) :: Clock
    @assert master.id == 1 "you can get parallel clocks only from a master clock"
    cix = [ac.id for ac in master.ac]
    if id in cix
        ch = master.ac[findfirst(x->x==id, cix)].ch
        put!(ch, Query())
        return take!(ch).x
    else
        return master
    end
end
