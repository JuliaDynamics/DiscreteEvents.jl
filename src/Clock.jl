#
# simulation routines for discrete event simulation
#

@enum Timing at after

"Create a simulation event: an expression to be executed at an event time."
mutable struct SimEvent
    "expression to be evaluated at event time"
    expr::Expr
    "evaluation scope"
    scope::Module
    "event time"
    at::Float64
end


"""
    Clock(time::Number=0)

Create a new simulation clock.

# Arguments
- `time::Number`: start time for simulation.
"""
mutable struct Clock
    state::SState
    time::Float64
    events::PriorityQueue{SimEvent,Float64}
    end_time::Float64
    counter::Int64
    logger::SEngine

    Clock(time::Number=0) =
        new(Undefined(), time, PriorityQueue{SimEvent,Float64}(), 0, 0, Logger())
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

# returns
scheduled simulation time for that event, may return a different result from
iterative applivations of `nextfloat(at)` if there were yet events scheduled
for that time.
"""
function event!(sim::Clock, expr::Expr, t::Number; scope::Module=Main)::Float64
    while any(i->i==t, values(sim.events)) # in case an event at that time exists
        t = nextfloat(float(t))                  # increment scheduled time
    end
    ev = SimEvent(expr, scope, t)
    sim.events[ev] = t
    return t
end

"""
    event!(sim::Clock, expr::Expr, at::Number)

Schedule an expression for execution at a given simulation time.

# Arguments
- `sim::Clock`: simulation clock
- `expr::Expr`: an expression
- `T::Timing`: a timing, `at` or `after`
- `t::Float64`: simulation time
- `scope::Module=Main`: scope for the expression to be evaluated

# returns
scheduled simulation time for that event, may return a different result from
iterative applivations of `nextfloat(at)` if there were yet events scheduled
for that time.
"""
function event!(sim::Clock, expr::Expr, T::Timing, t::Number; scope::Module=Main)
    if T == after
        t += sim.time
    end
    event!(sim, expr, t, scope=scope)
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

function step!(sim::Clock, ::Union{Idle,Busy,Halted}, ::Step)
    if length(sim.events) ≥ 1
        ev = dequeue!(sim.events)
        sim.time = ev.at
        Core.eval(ev.scope, ev.expr)
    else
        println(stderr, "step!: no event in queue!")
    end
end

function step!(sim::Clock, ::Idle, σ::Run)
    sim.end_time = sim.time + σ.duration
    sim.counter = 0
    sim.state = Busy()
    while length(sim.events) > 0
        if nextevent(sim).at ≤ sim.end_time
            step!(sim, sim.state, Step())
            sim.counter += 1
        else
            break
        end
        if sim.state == Halted()
            return
        end
    end
    sim.time = sim.end_time
    sim.state = Idle()
    println("Finished: ", sim.counter, " events, simulation time: ", sim.time)
end

function step!(sim::Clock, ::Busy, ::Stop)
    sim.state = Halted()
    println("Halted: ", sim.counter, " events, simulation time: ", sim.time)
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
