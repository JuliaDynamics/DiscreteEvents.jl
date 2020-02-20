#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

import Base.invokelatest

function event! end

# Function barrier for functions and expressions as well for arguments and
# keywords of a `fun`. It allows Expr, Symbol and `fun` as arguments for `fun`.
_evaluate(y) = y    # catchall, gives back the argument
function _evaluate(y::T) where {T<:Function}
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
_evaluate(y::T) where {T<:Tuple{Vararg{<:Any}}} = _evaluate.(y)
_evaluate(kw::T) where {T<:Iterators.Pairs} = (; zip(keys(kw), map(i->_evaluate(i), values(kw)) )...)
function _evaluate(y::T) where {T<:Union{Symbol,Expr}}  # Symbol,Expr: eval
    try
        ret = Core.eval(Main,y)
        @warn "Evaluating expressions is slow, use functions instead" maxlog=1
        return ret
    catch
        return y
    end
end

# Function barrier for executing `fun`s.
_invoke(f::F, ::Nothing, ::Nothing) where {F<:Function} = f()
_invoke(f::F, arg::T, ::Nothing) where {F<:Function,T<:Tuple{Vararg{<:Any}}} = f(_evaluate.(arg)...)
_invoke(f::F, ::Nothing, kw) where {F<:Function} = f(; _evaluate(kw)...)
_invoke(f::F, arg::T, kw) where {F<:Function,T<:Tuple{Vararg{<:Any}}} = f(_evaluate.(arg)...; _evaluate(kw)...)
_invoke(f::typeof(event!), arg::T, ::Nothing) where {T<:Tuple{Vararg{<:Any}}} = f(arg...)
_invoke(f::typeof(event!), ::Nothing, kw) = f(; kw...)
_invoke(f::typeof(event!), arg::T, kw) where {T<:Tuple{Vararg{<:Any}}} = f(arg..., kw...)

"""
    fun(f::Function, args...; kwargs...)

Return a closure of a function `f` and its arguments for later execution.

# Arguments
The arguments `args...` and keyword arguments `kwargs...` to fun are passed
to `f` at execution but may change their values between
beeing captured in `fun` and `f`s later execution. If `f` needs their
current values at execution time there are two possibilities:
1. `fun` can take symbols, expressions, `fun`s or function closures at the
    place of values or variable arguments. They are evaluated just before
    being passed to f. There is one exception: if `f` is an `event!`, its
    arguments are passed on unevaluated.
2.  A mutable type argument (Array, struct ...) is always current. You can
    also change its content from within a function.

!!! warning "Evaluating symbols and expressions is slow"
    … and should be avoided in time critical parts of applications. You will
    get a one time warning if you use that feature. They can be replaced
    easily by `fun`s or function closures. See the Performance section in the
    documentation and the subsequent examples.

!!! note "Symbols and expressions"
    … are evaluated at global scope in Module `Main` only. Other modules using
    `Simulate.jl` cannot use this feature and have to use functions.

# Returns
A function closure of f(args..., kwargs...), which can be evaluated without
arguments.

# Examples
```jldoctest
julia> using Simulate

julia> g(x; y=1) = x+y
g (generic function with 1 method)

julia> x = 1
1

julia> gg = fun(g, :x, y=2);   # we pass x as a symbol to fun

julia> x += 1   # a becomes 2
2

julia> gg()     # at execution g gets a current x and gives a warning
┌ Warning: Evaluating expressions is slow, use functions instead
[...]
4

julia> hh = fun(g, fun(()->x), y=3);   # reference x with an anonymous fun

julia> x += 1   # x becomes 3
3

julia> hh()     # at execution g gets again a current x
6

julia> ii = fun(g, ()->x, y=4);  # reference x with an anonymous function

julia> x += 1   # x becomes 4
4

julia> ii()     # ok, g gets an updated x
8
```
"""
@inline function fun(f::F, args::Vararg{Any, N}; kwargs...) where {F<:Function,N}
    args = ifelse(isempty(args), nothing, args)
    kwargs = ifelse(isempty(kwargs), nothing, kwargs)
    () -> _invoke(f, args, kwargs)
end
# @inline function fun(@nospecialize(f), @nospecialize args...; kwargs...)
#     args = ifelse(isempty(args), nothing, args)
#     kwargs = ifelse(isempty(kwargs), nothing, kwargs)
#     () -> _invoke(f, args, kwargs)
# end
