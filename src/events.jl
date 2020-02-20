#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
# this implements the event handling
#

# Return the next scheduled event.
_nextevent(c::Clock) = peek(c.sc.events)[1]

# Return the internal time (unitless) of next scheduled event.
_nextevtime(c::Clock) = peek(c.sc.events)[2]

# Execute or evaluate the next timed event on a clock c.
@inline function _event!(c::Clock)
    c.time = c.tev
    ev = dequeue!(c.sc.events)
    _evaluate(ev.ex)
    c.evcount += 1
    ev.Δt > 0.0 && event!(c, ev.ex, c.time + ev.Δt, cycle=ev.Δt)
end

# First execute all sampling expressions in a schedule, then evaluate all
# conditional events and if conditions are met, execute them.
function _tick!(c::Clock)
    c.time = c.tn
    foreach(x -> _evaluate(x.ex), c.sc.samples)  # exec sampling
    # then lookup conditional events
    ix = findfirst(x->all(_evaluate(x.cond)), c.sc.cevents)
    while ix !== nothing
        _evaluate(splice!(c.sc.cevents, ix).ex)
        if isempty(c.sc.cevents)
            if isempty(c.sc.samples) && isempty(c.ac) # no sampling and active clocks
                c.Δt = 0.0 # delete sample rate
            end
            break
        end
        ix = findfirst(x->all(_evaluate(x.cond)), c.sc.cevents)
    end
    c.scount +=1
end

# ------------------------------------------------------
# step forward to next tick or scheduled event. At a tick evaluate
# 1) all sampling functions or expressions,
# 2) all conditional events, then
# 3) if an event is encountered, trigger the event.
# The internal clock times `c.tev` and `c.tn` are always at least `c.time`.
# -------------------------------------------------------
@inline function _step!(c::Clock)
    c.state = Busy()
    if (c.tev ≤ c.time) && (length(c.sc.events) > 0)
        c.tev = _nextevtime(c)
    end

    if !isempty(c.sc.events)
        if c.Δt > 0.0
            if c.tn <= c.tev     # if t_next_tick  ≤ t_next_event
                _tick!(c)
                if c.tn == c.tev # an event is scheduled at the same time
                    _event!(c)
                end
                c.tn += c.Δt
            else
                _event!(c)
            end
        else
            _event!(c)
        end
    elseif c.Δt > 0.0
        _tick!(c)
        c.tn += c.Δt
    else
        error("_step!: nothing to evaluate")
    end
    !isempty(c.processes) && yield() # let processes run
    c.tev = !isempty(c.sc.events) ? _nextevtime(c) : c.end_time
    (c.state == Busy()) && (c.state = Idle())
end

# ----------------------------------------------------
# execute all events in a clock cycle, then do the periodic actions
# ----------------------------------------------------
function _cycle!(clk::Clock, Δt::Float64, sync::Bool=false)
    clk.state = Busy()
    tcyc = clk.time + Δt
    clk.tev = length(clk.sc.events) ≥ 1 ? _nextevtime(clk) : clk.time
    while clk.time ≤ tcyc
        if (clk.tev ≤ tcyc) && length(clk.sc.events) ≥ 1
            _event!(clk)
        else
            clk.time = tcyc
            break
        end
        length(clk.processes) == 0 || yield() # let processes run
    end
    if !sync
        clk.tn = tcyc
        _tick!(clk)
    end
    (clk.state == Busy()) && (clk.state = Idle())
end
