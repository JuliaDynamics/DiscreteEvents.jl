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
        @warn "Evaluating expressions is slow, use functions instead" maxlog=1
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

Return a closure of a function `f` and its arguments for later execution.

# Arguments
`fun` can take any arguments. Arguments of `f` may change their values between
beeing captured in `fun` and `f`s later execution. If `f` must evaluate their
current values at execution time there are two possibilities:
1. `fun` can take symbols, expressions or other `fun`s as arguments. They
    are evaluated just before being passed to f. There is one exception:
    if `f` is an `event!`, its arguments are passed on unevaluated.
2.  Composite variables (Arrays, structs ...) are always current.

!!! warning "Evaluating symbols and expressions is slow"
    … and should be avoided in time critical parts of applications. You will get a one
    time warning if you use that feature. See the Performance section in the
    documentation.

# Returns
It returns a function closure of f(args..., kwargs...) which has to be called
with a `Module` argument (for evaluation scope of symbols and expressions).

# Examples
```jldoctest
julia> using Simulate

julia> g(x; y=1) = x+y
g (generic function with 1 method)

julia> a = 1
1

julia> gg = fun(g, :a, y=2)   # we pass a as a symbol to fun
#12 (generic function with 1 method)

julia> a += 1                 # a gets 2
2

julia> gg(Main)               # at execution g gets the current value of a
┌ Warning: Evaluating expressions is slow, use functions instead
└ @ Simulate ~/.julia/dev/Simulate/src/fclosure.jl:32
4

julia> hh = fun(g, fun(()->a), y=3)   # reference a with an anonymous function
#12 (generic function with 1 method)

julia> a += 1                 # a gets 3
3

julia> hh(Main)               # at execution g gets again a current a
6

julia> ii = fun(g, (m)->a, y=4)  # reference a with a mock fun, taking a module m
#12 (generic function with 1 method)

julia> a += 1                 # a gets 4
4

julia> ii(Main)
8
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
