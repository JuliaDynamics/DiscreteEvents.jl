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
evaluate(y,  m) = y    # catchall, gives back the argument
evaluate(y::Fun, m) = sfExec(y, m)   # Fun: recursively call sfexec
evaluate(arg::Tuple, m) = map(i->evaluate(i, m), arg)
evaluate(kw::Iterators.Pairs, m) = (; zip(keys(kw), map(i->evaluate(i, m), values(kw)) )...)
function evaluate(y::T, m) where {T<:Union{Symbol,Expr}}  # Symbol,Expr: eval
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
function sfExec(x, m)
    try
        _invoke(x.f, x.arg, x.kw, m)
    catch exc
        if exc isa MethodError
            _invokelt(x.f, x.arg, x.kw, m)
        else
            rethrow(exc)
        end
    end
end
# function sfExec(x::Fun, m::Module)
#     if (threadid() == 1) !! (parentmodule(x.f) != Main)
#         _invoke(x.f, x.arg, x.kw, m)
#     else
#         _invokelt(x.f, x.arg, x.kw, m)
#     end
# end

"Function barrier for executing Funs."
_invoke(@nospecialize(f), ::Nothing, ::Nothing, m) = f()
_invoke(@nospecialize(f), arg, ::Nothing, m) = f(evaluate(arg,m)...)
_invoke(@nospecialize(f), ::Nothing, kw, m) = f(; evaluate(kw,m)...)
_invoke(@nospecialize(f), arg, kw, m) = f(evaluate(arg,m)..., evaluate(kw,m)...)
_invoke(f::typeof(event!), arg, ::Nothing, m) = f(arg...)
_invoke(f::typeof(event!), ::Nothing, kw, m) = f(; kw...)
_invoke(f::typeof(event!), arg, kw, m) = f(arg..., kw...)

"Function barrier for executing Funs with invokelatest."
_invokelt(f, ::Nothing, ::Nothing, m) = invokelatest(f)
_invokelt(f, arg, ::Nothing, m) = invokelatest(f, evaluate(arg,m)...)
_invokelt(f, ::Nothing, kw, m) = invokelatest(f; evaluate(kw,m)...)
_invokelt(f, arg, kw, m) = invokelatest(f, evaluate(arg,m)...; evaluate(kw,m)...)

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
