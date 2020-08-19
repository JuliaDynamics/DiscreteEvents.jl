#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
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

Save a function `f` and its arguments in a closure for later execution.

# Arguments
The arguments `args...` and keyword arguments `kwargs...` to fun are passed to `f` at
execution but may change their values between beeing captured in `fun` and `f`s later
execution. If `f` needs their current values at execution time there are two possibilities:
1. `fun` can take `fun`s, function closures, symbols or expressions at the place of values
    or variable arguments. They are evaluated at event time just before being passed to f.
    There is one exception: if `f` is an `event!`, its arguments are passed on unevaluated.
2.  A mutable type argument (Array, struct ...) is always current. You can
    also change its content from within a function.

If using `Symbol`s or `Expr` in `fun` you get a one time warning. They are 
evaluated at global scope in Module `Main` only and therefore cannot
be used by other modules.
"""
@inline function fun(f::F, args::Vararg{Any, N}; kwargs...) where {F<:Function,N}
    args = ifelse(isempty(args), nothing, args)
    kwargs = ifelse(isempty(kwargs), nothing, kwargs)
    () -> _invoke(f, args, kwargs)
end
