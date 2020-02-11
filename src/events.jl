#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
# this implements the event handling
#

"""
    nextevent(c::Clock)

Return the next scheduled event.
"""
nextevent(c::Clock) = peek(c.sc.events)[1]

"""
    nextevtime(c::Clock)

Return the internal time (unitless) of next scheduled event.
"""
nextevtime(c::Clock) = peek(c.sc.events)[2]

"""
    do_event!(c::Clock)

Execute or evaluate the next timed event on a clock c.
"""
function do_event!(c::Clock)
    c.time = c.tev
    ev = dequeue!(c.sc.events)
    evaluate(ev.ex)
    c.evcount += 1
    if ev.Δt > 0.0  # schedule repeat event
        event!(c, ev.ex, c.time + ev.Δt, scope=ev.scope, cycle=ev.Δt)
    end
    c.tev = length(c.sc.events) ≥ 1 ? nextevtime(c) : c.time
end

"""
    do_tick!(s::Schedule)

First execute all sampling expressions in a schedule, then evaluate all
conditional events and if conditions are met, execute them.
"""
function do_tick!(c::Clock)
    c.time = c.tn
    foreach(x -> evaluate(x.ex), c.sc.samples)  # exec sampling
    # then lookup conditional events
    ix = findfirst(x->all(evaluate(x.cond)), c.sc.cevents)
    while ix !== nothing
        evaluate(splice!(c.sc.cevents, ix).ex)
        if isempty(c.sc.cevents)
            if isempty(c.sc.samples) && isempty(c.ac) # no sampling and active clocks
                c.Δt = 0.0 # delete sample rate
            end
            break
        end
        ix = findfirst(x->all(evaluate(x.cond)), c.sc.cevents)
    end
    c.scount +=1
end

"""
    do_step!(c::Clock)

step forward to next tick or scheduled event.
"""
function do_step!(c::Clock)
    c.state = Busy()
    if (c.tev ≤ c.time) && (length(c.sc.events) > 0)
        c.tev = nextevtime(c)
    end

    if length(c.sc.events) > 0
        if c.Δt > 0.0
            if c.tn <= c.tev     # if t_next_tick  ≤ t_next_event
                do_tick!(c)
                if c.tn == c.tev # an event is scheduled at the same time
                    do_event!(c)
                end
                c.tn += c.Δt
            else
                do_event!(c)
            end
        else
            do_event!(c)
            c.tn = c.time
        end
    elseif c.Δt > 0.0
        do_tick!(c)
        c.tn += c.Δt
        c.tev = c.time
    else
        error("do_step!: nothing to evaluate")
    end
    length(c.processes) == 0 || yield() # let processes run
    (c.state == Busy()) && (c.state = Idle())
end
