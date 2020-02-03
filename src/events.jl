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

"""
    evaluate(y,  m::Module)

Function barrier for arguments and keywords of a Fun. This allows Expr, Symbol
and Fun as arguments and keyword values.
"""
evaluate(y,  m::Module) = y    # catchall, gives back the argument
evaluate(y::Fun, m::Module) = sfExec(y, m)   # Fun: recursively call sfexec
function evaluate(y::Union{Symbol,Expr}, m::Module)  # Symbol,Expr: eval
    try
        ret = Core.eval(m, y)
        @warn "Evaluating expressions is slow, use `Fun` instead" maxlog=1
        return ret
    catch
        return y
    end
end

"""
    sfExec(x::Fun, m::Module)

Execute a Fun x.

- if x.f is an event!, its args and kws must be maintained for later evaluation,
    otherwise evaluate them now before passing them to x.f,
- branch to different invocation methods depending on args or kws,
- if x.f is not from Main and we are not on thread 1, call it with invokelatest
    to avoid a world age situation (it may be too new).
"""
function sfExec(x::Fun, m::Module)
    f_std = (parentmodule(x.f) != Main) || (threadid() == 1)
    if x.arg === nothing
        if x.kw === nothing
            f_std ? x.f() : invokelatest(x.f)  # 1. no args and kws
        else
            kw = x.f === event! ? x.kw : (; zip(keys(x.kw), map(i->evaluate(i, m), values(x.kw)) )...)
            f_std ? x.f(; kw...) : invokelatest(x.f; kw...)    # 2. only kws
        end
    else
        if x.kw === nothing
            arg = x.f === event! ? x.arg : map(i->evaluate(i, m), x.arg)
            f_std ? x.f(arg...) : invokelatest(x.f, arg...)    # 3. only args
        else
            if x.f === event!
                arg = x.arg; kw = x.kw
            else
                arg = map(i->evaluate(i, m), x.arg)
                kw = (; zip(keys(x.kw), map(i->evaluate(i, m), values(x.kw)) )...)
            end
            f_std ? x.f(arg...; kw...) : invokelatest(x.f, arg...; kw...) # 4. args and kws
        end
    end
end


# "Forward an expression to `evaluate`."
# sfExec(x::Expr, m::Module) = evaluate(x, m)

"""
    evExec(ex, m::Module=Main)

Function barrier for different ex: forward an event's `Fun`s or expressions
to further execution or evaluation.

# Return
the evaluated value or a tuple of evaluated values.
"""
evExec(ex::Fun, m::Module=Main) = sfExec(ex, m)
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
    foreach(x -> evExec(x.ex, x.scope), c.sc.samples)  # exec sampling
    # then lookup conditional events
    ix = findfirst(x->all(evExec(x.cond, x.scope)), c.sc.cevents)
    while ix !== nothing
        evExec(splice!(c.sc.cevents, ix).ex)
        if isempty(c.sc.cevents)
            if isempty(c.sc.samples) && isempty(c.ac) # no sampling and active clocks
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
