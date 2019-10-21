#
# simulation routines for discrete event simulation
#

"""
    Timing

Enumeration type for scheduling events and timed conditions:

- `at`: schedule an event at agiven time
- `after`: schedule an event a given time after current time
- `every`: schedule an event every given time from now
- `before`: a timed condition is true before a given time.
"""
@enum Timing at after every before

"Create a simulation event: an expression to be executed at an event time."
struct SimEvent
    "expression to be evaluated at event time"
    expr::Expr
    "evaluation scope"
    scope::Module
    "event time"
    t::Float64
    "repeat time"
    Δt::Float64
end

"Create a sample expression"
struct Sample
    "expression to be evaluated at sample time"
    expr::Expr
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
mutable struct Clock
    "clock state"
    state::SState
    "clock time"
    time::Float64

    "scheduled events"
    events::PriorityQueue{SimEvent,Float64}
    "end time for simulation"
    end_time::Float64
    "event evcount"
    evcount::Int64
    "next event time"
    tev::Float64

    "sampling time, timestep between ticks"
    Δt::Float64
    "Array of sampling expressions to evaluate at each tick"
    sexpr::Array{Sample}
    "next sample time"
    tsa::Float64

    "logger"               # do we need this anyway ?
    logger::SEngine

    Clock(Δt::Number=0; t0::Number=0) = new(Undefined(), t0,
                                PriorityQueue{SimEvent,Float64}(), 0, 0, 0,
                                Δt, Sample[], t0 + Δt,
                                Logger())
end

"Return the current simulation time."
now(sim::Clock) = sim.time

"Return the next scheduled event"
nextevent(sim::Clock) = peek(sim.events)[1]

"Return the time of next scheduled event"
nextevtime(sim::Clock) = peek(sim.events)[2]

"""
    event!(sim::Clock, expr::Expr, at::Number)

Schedule an expression for execution at a given simulation time.

# Arguments
- `sim::Clock`: simulation clock
- `expr::Expr`: an expression
- `t::Float64`: simulation time
- `scope::Module=Main`: scope for the expression to be evaluated
- `cycle::Float64=0.0`: repeat cycle time for the event

# returns
Scheduled simulation time for that event.

May return a time `t > at` from repeated applications of `nextfloat(at)`
if there were yet events scheduled for that time.
"""
function event!(sim::Clock, expr::Expr, t::Number;
                scope::Module=Main, cycle::Number=0.0)::Float64
    while any(i->i==t, values(sim.events)) # in case an event at that time exists
        t = nextfloat(float(t))                  # increment scheduled time
    end
    ev = SimEvent(expr, scope, t, cycle)
    sim.events[ev] = t
    return t
end

"""
    event!(sim::Clock, expr::Expr, T::Timing, t::Number; scope::Module=Main)

Schedule an expression for execution at a given simulation time.

# Arguments
- `sim::Clock`: simulation clock
- `expr::Expr`: an expression
- `T::Timing`: a timing, `at`, `after` or `every` (`before` behaves like `at`)
- `t::Float64`: time, time delay or repeat cycle depending on `T`
- `scope::Module=Main`: scope for the expression to be evaluated

# returns
scheduled simulation time for that event.
"""
function event!(sim::Clock, expr::Expr, T::Timing, t::Number; scope::Module=Main)
    if T == after
        event!(sim, expr, t + sim.time, scope=scope)
    elseif T == every
        event!(sim, expr, sim.time, scope=scope, cycle=t)
    else
        event!(sim, expr, t, scope=scope)
    end
end

"set the clock's sample time"
function sample_time!(sim::Clock, Δt::Number)
    sim.Δt = Δt
    sim.tsa = sim.time + Δt
end

"enqueue an expression for sampling."
sample!(sim::Clock, expr::Expr; scope::Module=Main) =
                            push!(sim.sexpr, Sample(expr, scope))

"initialize, startup logger"
function step!(sim::Clock, ::Undefined, ::Init)
    step!(sim.logger, sim.logger.state, Init(sim))
    sim.state = Idle()
end

"if uninitialized, initialize first"
function step!(sim::Clock, ::Undefined, σ::Union{Step,Run})
    step!(sim, sim.state, Init(0))
    step!(sim, sim.state, σ)
end

"""
    step!(sim::Clock, ::Union{Idle,Busy,Halted}, ::Step)

step forward to next tick or scheduled event"

At a tick evaluate all sampling expressions, or, if an event is encountered
evaluate the event expression.
"""
function step!(sim::Clock, ::Union{Idle,Busy,Halted}, ::Step)

    function exec_next_event()
        sim.time = sim.tev
        ev = dequeue!(sim.events)
        Core.eval(ev.scope, ev.expr)
        sim.evcount += 1
        if ev.Δt > 0.0  # schedule repeat event
            event!(sim, ev.expr, sim.time + ev.Δt, scope=ev.scope, cycle=ev.Δt)
        end
        if length(sim.events) ≥ 1
            sim.tev = nextevtime(sim)
        end
    end

    function exec_next_tick()
        sim.time = sim.tsa
        for s ∈ sim.sexpr
            Core.eval(s.scope, s.expr)
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
    println("Finished: ", sim.evcount, " events, simulation time: ", sim.time)
end

function step!(sim::Clock, ::Busy, ::Stop)
    sim.state = Halted()
    println("Halted: ", sim.evcount, " events, simulation time: ", sim.time)
end

function step!(sim::Clock, ::Halted, ::Resume)
    sim.state = Idle()
    step!(sim, sim.state, Run(sim.end_time - sim.time))
end

"Run a simulation for a given duration. Call scheduled events in that timeframe."
run!(sim::Clock, duration::Number) = step!(sim, sim.state, Run(duration))

"Take one simulation step, execute the next tick or event."
incr!(sim::Clock) = step!(sim, sim.state, Step())

"Stop a running simulation."
stop!(sim::Clock) = step!(sim, sim.state, Stop())

"Resume a halted simulation."
resume!(sim::Clock) = step!(sim, sim.state, Resume())

"initialize a clock"
init!(sim::Clock) = step!(sim, sim.state, Init(""))
