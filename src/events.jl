#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
# this implements the event handling
#

import Base.invokelatest

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

"catchall function: forward the value y"
evaluate(y::Any,  m::Module) = y

"recursive call to `sfExec` for a nested `SimFunction`."
evaluate(y::SimFunction, m::Module) = sfExec(y, m)

"evaluate a symbol or expression and give a warning."
function evaluate(y::Union{Symbol,Expr}, m::Module)
    try
        ret = Core.eval(m, y)
        @warn "Evaluating expressions is slow, use `SimFunction` instead" maxlog=1
        return ret
    catch
        return y
    end
end

"execute a `SimFunction`"
function sfExec(x::SimFunction, m::Module)
    if x.efun == event!  # should arguments be maintained?
        arg = x.arg; kw = x.kw
    else                 # otherwise evaluate them
        x.arg === nothing || (arg = map(i->evaluate(i, x.emod), x.arg))
        x.kw === nothing  || (kw = (; zip(keys(x.kw), map(i->evaluate(i, x.emod), values(x.kw)) )...))
    end
    try
        if x.kw === nothing
            return x.arg === nothing ? x.efun() : x.efun(arg...)
        else
            return x.arg === nothing ? x.efun(; kw...) : x.efun(arg...; kw...)
        end
    catch exc
        if exc isa MethodError
            if x.kw === nothing
                return x.arg === nothing ? invokelatest(x.efun) : invokelatest(x.efun, arg...)
            else
                return x.arg === nothing ? invokelatest(x.efun; kw...) : invokelatest(x.efun, arg...; kw...)
            end
        end
    end
end

"Forward an expression to `evaluate`."
sfExec(x::Expr, m::Module) = evaluate(x, m)

"""
    evExec(ex::Union{SimExpr, Tuple, m::Module=Main)

Forward an event's `SimFunction`s or expressions to further execution or evaluation.

# Return
the evaluated value or a tuple of evaluated valuesch.
"""
evExec(ex::SimFunction, m::Module=Main) = sfExec(ex, m)
evExec(ex::Expr, m::Module=Main) = evaluate(ex, m)
evExec(ex::Tuple, m::Module=Main) = map(x->evExec(x, m), ex)

"""
    do_event!(c::Clock)

Execute or evaluate the next timed event on a clock c.
"""
function do_event!(c::Clock)
    c.time = c.tev
    ev = dequeue!(c.sc.events)
    evExec(ev.ex, ev.scope)
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
    foreach(x -> evExec(x.ex, x.scope), c.sc.sexpr)  # exec sampling
    # then lookup conditional events
    ix = findfirst(x->all(evExec(x.cond, x.scope)), c.sc.cevents)
    while ix !== nothing
        evExec(splice!(c.sc.cevents, ix).ex)
        if isempty(c.sc.cevents)
            if isempty(c.sc.sexpr) && isempty(c.ac) # no sampling and active clocks
                c.Δt = 0.0 # delete sample rate
            end
            break
        end
        ix = findfirst(x->all(evExec(x.cond, x.scope)), c.sc.cevents)
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
