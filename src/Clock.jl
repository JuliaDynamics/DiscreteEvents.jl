#
# simulation routines for discrete event simulation
#

@enum Timing at after every before

"Create a simulation event: an expression to be executed at an event time."
mutable struct SimEvent
    "expression to be evaluated at event time"
    expr::Expr
    "evaluation scope"
    scope::Module
    "event time"
    t::Float64
    "repeat time"
    Δt::Float64
end


"""
    Clock(time::Number=0)

Create a new simulation clock.

# Arguments
- `time::Number`: start time for simulation.
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
    "next tick time"
    tick::Float64
    "Array of expressions to evaluate at each tick"
    tickexpr::Array{Expr}
    "timestep between ticks"
    timestep::Float64
    "logger"               # do we need this anyway ?
    logger::SEngine

    Clock(time::Number=0, timestep::Number=0) =
        new(Undefined(), time, PriorityQueue{SimEvent,Float64}(), 0, 0,
            0, Expr[], timestep, Logger())
end

"Return the current simulation time."
now(sim::Clock) = sim.time

"Return the next scheduled event"
nextevent(sim::Clock) = peek(sim.events)[1]

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
scheduled simulation time for that event, may return a different result from
iterative applivations of `nextfloat(at)` if there were yet events scheduled
for that time.
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
        event!(sim, expr, now(sim), scope=scope, cycle=t)
    else
        event!(sim, expr, t, scope=scope)
    end
end

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

"step forward to next tick or scheduled event"
function step!(sim::Clock, ::Union{Idle,Busy,Halted}, ::Step)
    if length(sim.events) ≥ 1
        ev = dequeue!(sim.events)
        sim.time = ev.t
        Core.eval(ev.scope, ev.expr)
        if ev.Δt > 0.0  # schedule repeat event
            event!(sim, ev.expr, sim.time + ev.Δt, scope=ev.scope, cycle=ev.Δt)
        end
    else
        println(stderr, "step!: no event in queue!")
    end
end

function step!(sim::Clock, ::Idle, σ::Run)
    sim.end_time = sim.time + σ.duration
    sim.evcount = 0
    sim.state = Busy()
    while length(sim.events) > 0
        if nextevent(sim).t ≤ sim.end_time
            step!(sim, sim.state, Step())
            sim.evcount += 1
        else
            break
        end
        if sim.state == Halted()
            return
        end
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

"Take one simulation step, execute the next event."
step!(sim::Clock) = step!(sim, sim.state, Step())

"Stop a running simulation."
stop!(sim::Clock) = step!(sim, sim.state, Stop())

"Resume a halted simulation."
resume!(sim::Clock) = step!(sim, sim.state, Resume())

"initialize a clock"
init!(sim::Clock) = step!(sim, sim.state, Init(""))
