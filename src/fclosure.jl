#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

import Base.invokelatest

"""
    event!

An event! is a Julia function or expression or a tuple of them to execute at
a given event time or under given conditions.
"""
function event! end

"""
    evaluate(y,  m::Module)

Function barrier for arguments and keywords of a `fun`. This allows Expr, Symbol
and `fun` as arguments and keyword values.
"""
evaluate(y,  m) = y    # catchall, gives back the argument
evaluate(y::Function, m) = y(m)   # Function: recursively call fun
evaluate(arg::Tuple, m) = map(i->evaluate(i, m), arg)
evaluate(kw::Iterators.Pairs, m) = (; zip(keys(kw), map(i->evaluate(i, m), values(kw)) )...)
function evaluate(y::T, m) where {T<:Union{Symbol,Expr}}  # Symbol,Expr: eval
    try
        ret = Core.eval(m, y)
        @warn "Evaluating expressions is slow, use `fun` instead" maxlog=1
        return ret
    catch
        return y
    end
end

"Function barrier for executing `fun`s."
_invoke(@nospecialize(f), ::Nothing, ::Nothing, m) = f()
_invoke(@nospecialize(f), arg, ::Nothing, m) = f(evaluate(arg,m)...)
_invoke(@nospecialize(f), ::Nothing, kw, m) = f(; evaluate(kw,m)...)
_invoke(@nospecialize(f), arg, kw, m) = f(evaluate(arg,m)...; evaluate(kw,m)...)
_invoke(f::typeof(event!), arg, ::Nothing, m) = f(arg...)
_invoke(f::typeof(event!), ::Nothing, kw, m) = f(; kw...)
_invoke(f::typeof(event!), arg, kw, m) = f(arg..., kw...)

"Function barrier for executing `fun`s with invokelatest."
_invokelt(@nospecialize(f), ::Nothing, ::Nothing, m) = invokelatest(f)
_invokelt(@nospecialize(f), arg, ::Nothing, m) = invokelatest(f, evaluate(arg,m)...)
_invokelt(@nospecialize(f), ::Nothing, kw, m) = invokelatest(f; evaluate(kw,m)...)
_invokelt(@nospecialize(f), arg, kw, m) = invokelatest(f, evaluate(arg,m)...; evaluate(kw,m)...)

"""
    fun(f::Function, args..., kwargs...)

Saves a function and its arguments for later execution.

# Arguments
`fun` can take any arguments. If you want `f` at execution time to have current
arguments you can give symbols, expressions or other `fun`s. They are
then evaluated just before being passed to f. There is one exception: if f
is an `event!`, its arguments are not evaluated before execution.

!!! warn "Evaluating symbols and expressions is slow"
It should be avoided in time critical parts of applications. You will get a one
time warning if you use that feature. See the Performance section in the
documentation.

# Returns
It returns a closure of f(args..., kwargs...) which has to be called with a
`Module` argument (for evaluation scope of symbols and expressions).

# Examples
```jldoctest
```
"""
@inline function fun(@nospecialize(f), @nospecialize args...; kwargs...)
    args = ifelse(isempty(args), nothing, args)
    kwargs = ifelse(isempty(kwargs), nothing, kwargs)
    m -> begin
        if (parentmodule(f) != Main) || (threadid() == 1)
            _invoke(f, args, kwargs, m)
        else
            _invokelt(f, args, kwargs, m)
        end
    end
end
