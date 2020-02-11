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
    evaluate(y)

Function barrier for functions and expressions as well for arguments and
keywords of a `fun`. It allows Expr, Symbol and `fun` as arguments for `fun`.
"""
evaluate(y) = y    # catchall, gives back the argument
function evaluate(y::Function)
    # try
    #     y()
    # catch exc
    #     if exc isa MethodError
    #         invokelatest(y)
    #     else
    #         rethrow(exc)
    #     end
    # end
    if (threadid() == 1) # || (parentmodule(y) != Main)
        y()
    else
        invokelatest(y)
    end
end
evaluate(y::Tuple) = evaluate.(y)
evaluate(kw::Iterators.Pairs) = (; zip(keys(kw), map(i->evaluate(i), values(kw)) )...)
function evaluate(y::T) where {T<:Union{Symbol,Expr}}  # Symbol,Expr: eval
    try
        ret = Core.eval(Main,y)
        @warn "Evaluating expressions is slow, use functions instead" maxlog=1
        return ret
    catch
        return y
    end
end

"Function barrier for executing `fun`s."
_invoke(@nospecialize(f), ::Nothing, ::Nothing) = f()
_invoke(@nospecialize(f), arg, ::Nothing) = f(evaluate.(arg)...)
_invoke(@nospecialize(f), ::Nothing, kw) = f(; evaluate(kw)...)
_invoke(@nospecialize(f), arg, kw) = f(evaluate.(arg)...; evaluate(kw)...)
_invoke(f::typeof(event!), arg, ::Nothing) = f(arg...)
_invoke(f::typeof(event!), ::Nothing, kw) = f(; kw...)
_invoke(f::typeof(event!), arg, kw) = f(arg..., kw...)

"""
    fun(f::Function, args..., kwargs...)

Return a closure of a function `f` and its arguments for later execution.

# Arguments
`fun` can take any arguments. Arguments of `f` may change their values between
beeing captured in `fun` and `f`s later execution. If `f` must evaluate their
current values at execution time there are two possibilities:
1. `fun` can take symbols, expressions or other `fun`s as arguments. They
    are evaluated in global scope (Main) just before being passed to f.
    There is one exception: if `f` is an `event!`, its arguments are passed
    on unevaluated.
2.  Composite variables (Arrays, structs ...) are always current.

!!! warning "Evaluating symbols and expressions is slow"
    … and should be avoided in time critical parts of applications. You will get a one
    time warning if you use that feature. See the Performance section in the
    documentation.

# Returns
A function closure of f(args..., kwargs...), which can be evaluated without
arguments.

# Examples
```jldoctest
julia> using Simulate

julia> g(x; y=1) = x+y
g (generic function with 1 method)

julia> a = 1
1

julia> gg = fun(g, :a, y=2)   # we pass a as a symbol to fun
#12 (generic function with 1 method)

julia> a += 1   # a becomes 2
2

julia> gg()     # at execution g gets the current value of a
┌ Warning: Evaluating expressions is slow, use functions instead
└ @ Simulate ~/.julia/dev/Simulate/src/fclosure.jl:38
4

julia> hh = fun(g, fun(()->a), y=3)   # reference to a with an anonymous fun
#12 (generic function with 1 method)

julia> a += 1   # a becomes 3
3

julia> hh()     # at execution g gets again a current a
6

julia> ii = fun(g, ()->a, y=4)  # reference to a with an anonymous function
#12 (generic function with 1 method)

julia> a += 1   # a becomes 4
4

julia> ii()
8
```
"""
@inline function fun(@nospecialize(f), @nospecialize args...; kwargs...)
    args = ifelse(isempty(args), nothing, args)
    kwargs = ifelse(isempty(kwargs), nothing, kwargs)
    () -> _invoke(f, args, kwargs)
end
