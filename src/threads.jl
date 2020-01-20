#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
export multiply!, pclock

"""
```
ActiveClock(clock::Clock, master::Ref{Clock}, ch::Channel)
```
A thread specific clock which can be operated via a channel.

# Fields
- `clock::Clock`: the thread specific clock,
- `master::Ref{Clock}`: a pointer to the master clock (on thread 1),
- `ch::Channel`: the communication channel between the two.
"""
mutable struct ActiveClock <: Simulate.StateMachine
    clock::Clock
    master::Ref{Clock}
    ch::Channel
end

"Run an active clock for a given duration."
step!(A::ActiveClock, ::Idle, σ::Run) = do_run!(A.clock, σ.duration)

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

step!(A::ActiveClock, q::SState, σ::SEvent) =
          error("transition q=$q, σ=$σ not implemented")

"""
    activeClock(ch::Channel)

Operate an active clock on a given channel.
"""
function activeClock(ch::Channel)
    ac = ActiveClock(Clock(),        # create an active clock, for it …
                     take!(ch), ch)  # 4. get a pointer to the master clock
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

"""
    startup(ch::Channel)

Serves as task startup on a parallel thread.
"""
function startup(ch::Channel)
    put!(ch, threadid())   # 1. send threadid
    if take!(ch) == true   # 2. receive response, if true
        f = take!(ch)      # 3. receive function
        f(ch)              #    and call it
    else                   # else let task finish
    end
end

"""
    start_threads(f::Function, mul::Int=3)

Start a task on each available thread (other than 1).

# Arguments
- `f::Function`: function to start, has to take a channel as its only argument,
- `mul::Int=3`: startup multiplication factor,
"""
function start_threads(f::Function, mul::Int=3) :: Vector{AC}
    n = nthreads()                    # how many threads are available
    ac = AC[]                         # empty AC array
    ts = Vector{Int}()
    for i in 1:n*mul                  # n*mul trials
        ai = AC(Ref{Task}(), Channel(), 0)
        ai.ch = Channel(startup, taskref=ai.ref, spawn=true)
        ai.id = take!(ai.ch)          # 1. receive threadid from startup task
        push!(ac, ai)
    end

    ts = [t.id for t in ac]           # threadids of all startup tasks
    ix = indexin(2:n, ts)             # get first indices of threads > 1
    ix = ix[ix .!= nothing]           # in case one could not established
    foreach(t->put!(t.ch, true), ac[ix])   # 2. send true to one task on each thread
    foreach(t->put!(t.ch, false), ac[setdiff(1:n*mul,ix)]) # 2. send false to the rest
    ac = ac[ix]                       # keep the established ones
    foreach(t->put!(t.ch, f), ac)     # 3. sent them the function
    println("got $(length(ac)) threads parallel to master!")
    return ac
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
- `id::Int`: threadid of the active clock.
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
    cix = [ac.id for ac in master.ac]
    if id in cix
        ch = master.ac[findfirst(x->x==id, cix)].ch
        put!(ch, σ)
        return take!(ch)
    else
        return Response(id == 1 ? "id 1 is master" : "id $id not known")
    end
end
