#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#


"""
```
tau(sim::Clock, check::Function, x::Union{Number,Symbol}; m::Module=Main)
tau(check::Function, x::Union{Number,Symbol}; m::Module=Main)
```
Compare the current simulation time against a number or a variable.

# Arguments
- `sim::Clock`: clock variable, if not given, it is 𝐶.
- `check::Function`: a comparison operator like ≥, >, ==, <, ≤,
- `x::Union{Number,Symbol}`: a number or a symbolic variable like `:a`, a
    symbolic variable can be evaluated later at event time,
- `m::Module=Main`: the evaluation scope, if a symbolic variable is given.

# Examples
```jldoctest
julia> using Simulate

julia> tau(>=, 1)
false

julia> tau(<, 1)
true

julia> a = 1
1

julia> tau(<=, :a, @__MODULE__)
true
```
"""
function tau(sim::Clock, check::Function, x::Union{Number,Symbol}, m::Module=Main)
    @assert typeof(check) in typeof.([>=, >, ==, <, <=]) "$check is not a comparison operator"
    x isa Number ? check(tau(sim), x) : check(tau(sim), Core.eval(m, x))
end
tau(check::Function, x::Union{Number,Symbol}, m::Module=Main) = tau(𝐶, check, x, m)

"""
```
val(a::Union{Number, Symbol}, check::Function, x::Union{Number, Symbol}, m::Module=Main)
```
Compare two variables or numbers.

# Arguments

- `a`, `xUnion{Number, Symbol}`: a number or a symbolic variable like `:a`, a
    symbolic variable can be evaluated later at event time,
- `check::Function`: a comparison operator like ≥, >, ==, <, ≤,
- `m::Module=Main`: the evaluation scope, if a symbolic variable is given.

# Examples
```jldoctest
julia> using Simulate

julia> val(1, <=, 2)
true

julia> a = 1
1

julia> val(:a, <=, 2, @__MODULE__)
true
```
"""
function val(a::Union{Number, Symbol}, check::Function, x::Union{Number, Symbol},
             m::Module=Main)
    @assert typeof(check) in typeof.([>=, >, ==, <, <=]) "$check is not a comparison operator"
    a = a isa Number ? a : Core.eval(m, a)
    x = x isa Number ? x : Core.eval(m, x)
    check(a, x)
end

"""
```
@SF(f::Symbol, arg...)
@SF f arg...
```
create a `SimFunction` from arguments f, arg...

# Arguments
- `f::Symbol`: a function given as a symbol, e.g. `:f` if f() is your function,
- `arg...`: further arguments to your function

!!! note
    1. keyword arguments don't work with this macro, use SF instead.
    2. if you give `@SF` as argument(s) to a function, you must enclose it/them
        in parentheses `( @SF ... )` or `( (@SF ...), (@SF ...) )`.

# Examples
```@jldoctest
julia> using Simulate

julia> a = 1
1
julia> incra() = global a += 1             # create a simple increment function
incra (generic function with 1 method)

julia> event!((@SF incra), after, 3);      # schedule an increment after 3 time units

julia> a                                   # nothing happened to a
1

julia> run!(𝐶, 5)                          # run the simulation
"run! finished with 1 clock events, 0 sample steps, simulation time: 5.0"

julia> a                                   # now it should have been incremented
2

julia> event!((@SF incra), (@tau :>= 8));  # schedule a conditional event

julia> run!(𝐶, 5)
"run! finished with 0 clock events, 301 sample steps, simulation time: 10.0"

julia> a                                   # the conditional event was triggered
3

julia> event!(((@SF incra), (@SF incra)),  # two increments
        ((@tau :>= 12), (@val :a :<= 3))); # on two conditions

julia> run!(𝐶, 5)
"run! finished with 0 clock events, 201 sample steps, simulation time: 15.0"

julia> a                                   # two increments happened
5
```
"""
macro SF(f, arg...)
    return :( SimFunction( $(Core.eval(__module__, f)), $(arg...) ) )
end

"""
```
@SP(id, f::Symbol, arg...)
@SP id f arg...
```
create a `SimProcess` from arguments f, arg...

!!! note
    keyword arguments don't work with this macro, use SP instead.
"""
macro SP(id, f::QuoteNode, arg...)
    return :( SimProcess($id, $(Core.eval(__module__, f)), $(arg...) ) )
end

"""
```
@tau(sim::Clock)
@tau sim
@tau()
@tau
```
return the current simulation time.

# Arguments
- `sim::Clock`: if no clock argument is given, it returns 𝐶's time.
"""
macro tau(arg)
    return :( tau($(Core.eval(__module__, arg)) ))
end
macro tau()
    return :( tau(𝐶) )
end

"""
```
@tau(sim::Clock, check::Symbol, val)
@tau sim check val
@tau(check::Symbol, val)
@tau check val
```
create a `SimFunction` comparing current simulation time with a given value or
variable.

# Arguments
- `sim::Clock`: if no clock is given, it compares with 𝐶's time,
- `check::Symbol`: the check operator must be given as a symbol e.g. `:<`,
- `val::Union{Number, QuoteNode}`: a value or a symbolic variable,

!!! note
    If you give `@tau` as argument(s) to a function, you must enclose it/them
    in parentheses `( @tau ... )` or `( (@tau ...), (@tau ...) )`!

# Examples
```jldoctest
julia> using Simulate

julia> reset!(𝐶)
"clock reset to t₀=0.0, sampling rate Δt=0.0."
julia> sf = @tau :≥ 100;

julia> Simulate.simExec(sf)
false

julia> Simulate.simExec(@tau < 100)                ### wrong !!
ERROR: syntax: "<" is not a unary operator

julia> Simulate.simExec(@tau :< 100)               ### correct
true

julia> a = 1
1

julia> Simulate.simExec(@tau :< :a)
true

julia> event!(SF(()->global a+=1), (@tau :>= 3))   ### create a conditional event
0.0

julia> a
1

julia> run!(𝐶, 5)                                  ### run
"run! finished with 0 clock events, 301 sample steps, simulation time: 5.0"

julia> a
2
```
"""
macro tau(sim, check::QuoteNode, val::Union{Number, QuoteNode})
    return :( SimFunction(tau, $(Core.eval(__module__, sim)), $(eval(check)), $(esc(val)), $__module__) )
end
macro tau(check::QuoteNode, val::Union{Number, QuoteNode})
    return :( SimFunction(tau, $(eval(check)), $(esc(val)), $__module__) )
end

"""
```
@val(a, check::QuoteNode, b)
@val a check b
```
Create a Simfunction comparing two values a and b or two symbolic variables
:a and :b. The comparison operator must be given symbolically, e.g. `:≤`.

# Arguments
- `a, b`:: a number, expression or symbol
- `check::QuoteNode`: a comparison operator as a symbol like `:>` or `:≤`

!!! note
    If you give `@val` as argument(s) to a function, you must enclose it/them
    in parentheses `( @val ... )` or e.g. `( (@tau ...), (@val ...) `)!

# Examples
```jldoctest
julia> using Simulate

julia> reset!(𝐶)
"clock reset to t₀=0.0, sampling rate Δt=0.0."

julia> Simulate.simExec(@val 1 :≤ 2)
true

julia> a = 1
1

julia> Simulate.simExec(@val :a :≤ 2)
true

julia> event!(SF(()->global a+=1), ((@tau :>= 3), (@val :a :<= 3))); # a conditional event

julia> run!(𝐶, 5)
"run! finished with 0 clock events, 301 sample steps, simulation time: 5.0"

julia> a
2
```
"""
macro val(a, check::QuoteNode, b)
    return :( SimFunction(val, $(esc(a)), $(eval(check)), $(esc(b)), $__module__) )
end
