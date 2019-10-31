#
# simulation routines for discrete event simulation
#

"""
    Timing

Enumeration type for scheduling events and timed conditions:

- `at`: schedule an event at a given time
- `after`: schedule an event a given time after current time
- `every`: schedule an event every given time from now on
- `before`: a timed condition is true before a given time.
"""
@enum Timing at after every before

"""
    Time

`Time` is a number in `Sim.jl`
"""
const Time = Number

"""
    SimFunction(func::Function, arg...; kw...)

Type for preparing a function as an event to a simulation.

# Arguments
- `func::Function`: function to be executed at a later simulation time
- `arg...`: arguments to the function
- `kw...`: keyword arguments

Be aware that, if the variables stored in a SimFunction are composite types,
they can change until they are evaluated later by `func`. But that's the nature
of simulation.

# Example
```jldoctest
julia> using Sim

julia> f(a,b,c; d=4, e=5) = a+b+c+d+e  # define a function
f (generic function with 1 method)

julia> sf = SimFunction(f, 10, 20, 30, d=14, e=15)  # store it as SimFunction
SimFunction(f, (10, 20, 30), Base.Iterators.Pairs(:d => 14,:e => 15))

julia> sf.func(sf.arg...; sf.kw...)  # and it can be executed later
89

julia> d = Dict(:a => 1, :b => 2) # now we set up a dictionary
Dict{Symbol,Int64} with 2 entries:
  :a => 1
  :b => 2

julia> f(t) = t[:a] + t[:b] # and a function adding :a and :b
f (generic function with 2 methods)

julia> f(d)  # our add function gives 3
3

julia> ff = SimFunction(f, d)   # we set up a SimFunction
SimFunction(f, (Dict(:a => 1,:b => 2),), Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}}())

julia> d[:a] = 10  # later somehow we need to change d
10

julia> ff  # our SimFunction ff has changed too
SimFunction(f, (Dict(:a => 10,:b => 2),), Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}}())

julia> ff.func(ff.arg...; ff.kw...)  # and calling it gives a different result
12
```
"""
struct SimFunction
    func::Function
    arg::Tuple
    kw::Base.Iterators.Pairs

    SimFunction(func, arg...; kw...) = new(func, arg, kw)
end

"""
    SimEvent(expr::Expr, scope::Module, t::Time, Δt::Time)

Create a simulation event: an expression to be executed at event time.

# Arguments
- `expr::Expr`: expression to be evaluated at event time
- `scope::Module`: evaluation scope
- `t::Float64`: event time
- `Δt::Float64`: repeat rate with which the event gets repeated
"""
struct SimEvent
    "expression to be evaluated at event time"
    ex::Union{Expr, SimFunction}
    "evaluation scope"
    scope::Module
    "event time"
    t::Time
    "repeat time"
    Δt::Time
end

"""
    Sample(ex::Union{Expr, SimFunction}, scope::Module)

Create a sampling expression.

# Arguments
- `ex::{Expr, SimFunction}`: expression or function to be called at sample time
- `scope::Module`: evaluation scope
"""
struct Sample
    "expression or function to be called at sample time"
    ex::Union{Expr, SimFunction}
    "evaluation scope"
    scope::Module
end

"""
    Clock(Δt::Number=0; t0::Number=0)

Create a new simulation clock.

# Arguments
- `Δt::Number=0`: time increment
- `t0::Number=0`: start time for simulation.

If no Δt is given, the simulation doesn't tick, but jumps from event to event.
Δt can be set later with `sample_time!`.
"""
mutable struct Clock <: SEngine
    "clock state"
    state::SState
    "clock time"
    time::Time

    "scheduled events"
    events::PriorityQueue{SimEvent,Float64}
    "end time for simulation"
    end_time::Time
    "event evcount"
    evcount::Int64
    "next event time"
    tev::Time

    "sampling time, timestep between ticks"
    Δt::Time
    "Array of sampling expressions to evaluate at each tick"
    sexpr::Array{Sample}
    "next sample time"
    tsa::Time

    Clock(Δt::Number=0; t0::Number=0) = new(Undefined(), t0,
                                PriorityQueue{SimEvent,Float64}(), t0, 0, t0,
                                Δt, Sample[], t0 + Δt)
end

"""
```
𝐶
Clk
```
italic 𝐶 (`\\itC`+Tab) or `Clk` is the central `Clock()`-variable.

# Examples
```jldoctest
julia> using Sim

julia> 𝐶  # central clock
Clock(Sim.Idle(), 0, DataStructures.PriorityQueue{Sim.SimEvent,Float64,Base.Order.ForwardOrdering}(), 0, 0, 0, 0, Sim.Sample[], 0)
julia> Clk  # alias
Clock(Sim.Idle(), 0, DataStructures.PriorityQueue{Sim.SimEvent,Float64,Base.Order.ForwardOrdering}(), 0, 0, 0, 0, Sim.Sample[], 0)
julia> 𝐶.time
0
```
"""
𝐶 = Clk = Clock()

"""
```
τ(sim::Clock=𝐶)
tau(sim::Clock=Tau)
```
Return the current simulation time (τ=\tau+Tab).

# Examples
```jldoctest
julia> using Sim

julia> τ() # gives the central time
0
julia> tau() # alias, gives the central time
0
```
"""
τ(sim::Clock=𝐶) = sim.time
tau = τ

"""
```
sync!(sim::Clock, to::Clock=𝐶)
```
Force a synchronization of two clocks. Change all registered times of
`sim` accordingly.
"""
function sync!(sim::Clock, to::Clock=𝐶)
    Δt = to.time - sim.time
    sim.time += Δt
    sim.tsa  += Δt
    sim.tev  += Δt
    sim.end_time += Δt
    sim.Δt = to.Δt
    evq = PriorityQueue{SimEvent,Float64}()
    for (ev, t) ∈ pairs(sim.events)
        evq[ev] = t + Δt
    end
    sim.events = evq
end

"""
    reset!(sim::Clock, Δt::Number=0; t0::Time=0, hard::Bool=true)

reset a clock

# Arguments
- `sim::Clock`
- `Δt::Number=0`: time increment
- `t0::Time=0`: start time
- `hard::Bool=true`: time is reset, all scheduled events and sampling are
deleted. If hard=false, then only time is reset, event and sampling times are
adjusted accordingly.
"""
function reset!(sim::Clock, Δt::Number=0; t0::Time=0, hard::Bool=true)
    if hard
        sim.state = Idle()
        sim.time = t0
        sim.tsa = t0
        sim.tev = t0
        sim.end_time = t0
        sim.evcount = 0
        sim.Δt = Δt
        sim.events = PriorityQueue{SimEvent,Float64}()
    else
        sync!(sim, Clock(Δt, t0=t0))
    end
    "clock reset to t₀=$t0, sampling rate Δt=$Δt."
end

"""
    nextevent(sim::Clock)

Return the next scheduled event.
"""
nextevent(sim::Clock) = peek(sim.events)[1]

"""
    nextevtime(sim::Clock)

Return the time of next scheduled event.
"""
nextevtime(sim::Clock) = peek(sim.events)[2]

"""
    simExec(ex::Union{Expr,SimFunction}, m::Module=Main)

evaluate an expression or execute a SimFunction.
"""
simExec(ex::Union{Expr,SimFunction}, m::Module=Main) =
    isa(ex, SimFunction) ? ex.func(ex.arg...; ex.kw...) : Core.eval(m,ex)

"""
```
event!(sim::Clock, ex::Union{Expr, SimFunction}, t::Number; scope::Module=Main, cycle::Number=0.0)::Float64
event!(sim::Clock, ex::Union{Expr, SimFunction}, T::Timing, t::Number; scope::Module=Main)::Float64
```
Schedule a function or expression for a given simulation time.

# Arguments
- `sim::Clock`: simulation clock
- `ex::{Expr, SimFunction}`: an expression or SimFunction
- `t::Time`: simulation time
- `scope::Module=Main`: scope for the expression to be evaluated
- `cycle::Time=0.0`: repeat cycle time for the event
- `T::Timing`: a timing, `at`, `after` or `every` (`before` behaves like `at`)

# returns
Scheduled simulation time for that event.

May return a time `t > at` from repeated applications of `nextfloat(at)`
if there were yet events scheduled for that time.
"""
function event!(sim::Clock, ex::Union{Expr, SimFunction}, t::Time;
                scope::Module=Main, cycle::Time=0.0)::Float64
    while any(i->i==t, values(sim.events)) # in case an event at that time exists
        t = nextfloat(float(t))                  # increment scheduled time
    end
    ev = SimEvent(ex, scope, t, cycle)
    sim.events[ev] = t
    return t
end
function event!(sim::Clock, ex::Union{Expr, SimFunction}, T::Timing, t::Time; scope::Module=Main)
    if T == after
        event!(sim, ex, t + sim.time, scope=scope)
    elseif T == every
        event!(sim, ex, sim.time, scope=scope, cycle=t)
    else
        event!(sim, ex, t, scope=scope)
    end
end

"""
    sample_time!(sim::Clock, Δt::Time)

set the clock's sampling time starting from now (`𝐶(sim)`).

# Arguments
- `sim::Clock`
- `Δt::Number`: sample rate, time interval for sampling
"""
function sample_time!(sim::Clock, Δt::Time)
    sim.Δt = Δt
    sim.tsa = sim.time + Δt
end

"""
    sample!(sim::Clock, ex::Union{Expr, SimFunction}; scope::Module=Main)

enqueue an expression for sampling.

# Arguments
- `sim::Clock`
- `ex::Union{Expr, SimFunction}`: an expression or function
- `scope::Module=Main`: optional, a scope for the expression to be evaluated in
"""
sample!(sim::Clock, ex::Union{Expr, SimFunction}; scope::Module=Main) =
                            push!(sim.sexpr, Sample(ex, scope))

"""
    step!(sim::Clock, ::Undefined, ::Init)

initialize a clock.
"""
function step!(sim::Clock, ::Undefined, ::Init)
    sim.state = Idle()
end

"""
    step!(sim::Clock, ::Undefined, σ::Union{Step,Run})

if uninitialized, initialize and then Step or Run.
"""
function step!(sim::Clock, ::Undefined, σ::Union{Step,Run})
    step!(sim, sim.state, Init(0))
    step!(sim, sim.state, σ)
end

"""
    step!(sim::Clock, ::Union{Idle,Busy,Halted}, ::Step)

step forward to next tick or scheduled event.

At a tick evaluate all sampling expressions, or, if an event is encountered
evaluate the event expression.
"""
function step!(sim::Clock, ::Union{Idle,Busy,Halted}, ::Step)

    function exec_next_event()
        sim.time = sim.tev
        ev = dequeue!(sim.events)
        simExec(ev.ex, ev.scope)
        sim.evcount += 1
        if ev.Δt > 0.0  # schedule repeat event
            event!(sim, ev.ex, sim.time + ev.Δt, scope=ev.scope, cycle=ev.Δt)
        end
        if length(sim.events) ≥ 1
            sim.tev = nextevtime(sim)
        end
    end

    function exec_next_tick()
        sim.time = sim.tsa
        for s ∈ sim.sexpr
            simExec(s.ex, s.scope)
        end
        if (sim.tsa == sim.tev) && (length(sim.events) ≥ 1)
            exec_next_event()
        end
        sim.tsa += sim.Δt
    end

    if (sim.tev ≤ sim.time) && (length(sim.events) ≥ 1)
        sim.tev = nextevtime(sim)
    end

    if (length(sim.events) ≥ 1) | (sim.Δt > 0)
        if length(sim.events) ≥ 1
            if (sim.Δt > 0) && (sim.tsa ≤ sim.tev)
                exec_next_tick()
            else
                exec_next_event()
            end
        else
            exec_next_tick()
        end
    else
        println(stderr, "step!: nothing to evaluate")
    end
end

"""
    step!(sim::Clock, ::Idle, σ::Run)

Run a simulation for a given duration.

The duration is given with `Run(duration)`. Call scheduled events and evaluate
sampling expressions at each tick in that timeframe.
"""
function step!(sim::Clock, ::Idle, σ::Run)
    sim.end_time = sim.time + σ.duration
    sim.evcount = 0
    sim.state = Busy()
    if sim.Δt > 0
        sim.tsa = sim.time + sim.Δt
    end
    if length(sim.events) ≥ 1
        sim.tev = nextevtime(sim)
    end
    while any(i->(sim.time < i ≤ sim.end_time), (sim.tsa, sim.tev))
        step!(sim, sim.state, Step())
        if sim.state == Halted()
            return
        end
    end
    tend = sim.end_time

    # catch remaining events
    while (length(sim.events) ≥ 1) && (sim.tev ≤ tend + Base.eps(tend)*10)
        step!(sim, sim.state, Step())
        tend = nextfloat(tend)
    end

    sim.time = sim.end_time
    sim.state = Idle()
    "run! finished with $(sim.evcount) events, simulation time: $(sim.time)"
end

"""
    step!(sim::Clock, ::Busy, ::Stop)

Stop the clock.
"""
function step!(sim::Clock, ::Busy, ::Stop)
    sim.state = Halted()
    "Halted after $(sim.evcount) events, simulation time: $(sim.time)"
end

"""
    step!(sim::Clock, ::Halted, ::Resume)

Resume a halted clock.
"""
function step!(sim::Clock, ::Halted, ::Resume)
    sim.state = Idle()
    step!(sim, sim.state, Run(sim.end_time - sim.time))
end

"""
    step!(sim::Clock, q::SState, σ::SEvent)

catch all step!-function.
"""
function step!(sim::Clock, q::SState, σ::SEvent)
    println(stderr, "Warning: undefined transition ",
            "$(typeof(sim)), ::$(typeof(q)), ::$(typeof(σ)))\n",
            "maybe, you should reset! the clock!")
end

"""
    run!(sim::Clock, duration::Number)
Run a simulation for a given duration.

Call scheduled events and evaluate sampling expressions at each tick
in that timeframe.
"""
run!(sim::Clock, duration::Number) = step!(sim, sim.state, Run(duration))

"""
    incr!(sim::Clock)

Take one simulation step, execute the next tick or event.
"""
incr!(sim::Clock) = step!(sim, sim.state, Step())

"""
    stop!(sim::Clock)

Stop a running simulation.
"""
stop!(sim::Clock) = step!(sim, sim.state, Stop())

"""
    resume!(sim::Clock)

Resume a halted simulation.
"""
resume!(sim::Clock) = step!(sim, sim.state, Resume())

"""
    init!(sim::Clock)

initialize a clock.
"""
init!(sim::Clock) = step!(sim, sim.state, Init(""))
