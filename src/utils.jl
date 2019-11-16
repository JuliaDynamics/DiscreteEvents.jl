#
# Utilities
#

"""
```
tau(sim::Clock, check::Symbol, x::Union{Number,Symbol}; m::Module=Main)
tau(check::Symbol, x::Union{Number,Symbol}; m::Module=Main)
```
Compare the current simulation time against a number or a variable.

# Arguments
- `sim::Clock`: clock variable, if not given, it is 𝐶.
- `check::Symbol`: a comparison operator as a symbol like `:>`,
- `x::Union{Number,Symbol}`: a number or a symbolic variable like `:a`,
- `m::Module=Main`: the evaluation scope, if a symbolic variable is given.

# Examples
```jldoctest
julia> using Simulate

julia> tau(:>=, 1)
false
julia> tau(:<, 1)
true
julia> a = 1
1
julia> tau(:<=, :a)
true
```
"""
tau(sim::Clock, check::Symbol, x::Union{Number,Symbol}; m::Module=Main) =
        x isa Number ? eval(check)(tau(sim), x) : eval(check)(tau(sim), Core.eval(m, x))
tau(check::Symbol, x::Union{Number,Symbol}; m::Module=Main) = tau(𝐶, check, x, m=m)

"""
```
val(a::Union{Number, Symbol}, check::Symbol, x::Union{Number, Symbol}; m::Module=Main)
```
Compare two variables or numbers.

# Examples
```@jldoctest
julia> using Simulate

julia> val(1, :<=, 2)
true
julia> a = 1
1
julia> val(:a, :<=, 2)
true
```
"""
function val(a::Union{Number, Symbol}, check::Symbol, x::Union{Number, Symbol};
                  m::Module=Main)
    a = a isa Number ? a : Core.eval(m, a)
    x = x isa Number ? x : Core.eval(m, x)
    eval(check)(a, x)
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
    2. if you give @SF as argument(s) to a function, you must enclose it/them
        in parentheses ( @SF ... ) or ( (@SF ...), (@SF ...) )

# Examples
```@jldoctest
julia> using Simulate

julia> @SF :sin pi
SimFunction(sin, (π,), Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}}())
julia> a = 1
1
julia> incra() = global a += 1             # create a simple increment function
incra (generic function with 1 method)
julia> event!((@SF :incra), after, 3)      # schedule an increment after 3 time units
3.0
julia> a
1
julia> run!(𝐶, 5)
"run! finished with 1 clock events, 0 sample steps, simulation time: 5.0"
julia> a
2
julia> event!((@SF :incra), (@tau :>= 8))  # schedule a conditional increment
5.0
julia> run!(𝐶, 5)
"run! finished with 0 clock events, 500 sample steps, simulation time: 10.0"
julia> a
3
julia> event!(((@SF :incra), (@SF :incra)), ((@tau :>= 12), (@val :a :<= 3)))
10.0
julia> run!(𝐶, 5)
"run! finished with 0 clock events, 500 sample steps, simulation time: 15.0"
julia> a
5
```
"""
macro SF(f::QuoteNode, arg...)
    return :( SimFunction( Core.eval(Main,$f), $(arg...) ) )
end

"""
```
@SP(id, f::Symbol, input::Channel, output::Channel, arg...)
@SP id f input output arg...
```
create a `SimProcess` from arguments f, arg...

!!! note
    keyword arguments don't work with this macro, use SP instead.
"""
macro SP(id, f::Symbol, input::Channel, output::Channel, arg...)
    return :( SimProcess($id, $f, $input, $output, $(arg...) ) )
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
macro tau(sim)
    return :( tau($sim) )
end
macro tau()
    return :( tau(𝐶) )
end

"""
```
@tau(sim::Clock, check::Symbol, val::Union{Number, QuoteNode}, m::Module=Main)
@tau sim check val
@tau(check::Symbol, val::Number)
@tau check val
```
create a `SimFunction` comparing current simulation time with a given value or
variable.

# Arguments
- `sim::Clock`: if no clock is given, it compares with 𝐶's time,
- `check::Symbol`: the check operator must be given as a symbol e.g. `:<`,
- `val::Union{Number, QuoteNode}`: a value or a symbolic variable,
- `m::Module=Main`: evaluation scope for given symbolic variables.


!!! note
    If you give @tau as argument(s) to a function, you must enclose it/them
    in parentheses ( @tau ... ) or ( (@tau ...), (@tau ...) )!

# Examples
```jldoctest
julia> using Simulate

julia> s = @tau :≥ 100
SimFunction(Simulate.tau, (:≥, 100), Base.Iterators.Pairs(:m => Main))
julia> Simulate.simExec(s)
false
julia> Simulate.simExec(@tau < 100)         # wrong !!
ERROR: syntax: "<" is not a unary operator
julia> Simulate.simExec(@tau :< 100)
true
julia> a = 1
1
julia> Simulate.simExec(@tau :< :a)
true
julia> event!(:(a += 1), (@tau :>= 3))      # create a conditional event
0.0
julia> a
1
julia> run!(𝐶, 5)
"run! finished with 0 clock events, 500 sample steps, simulation time: 5.0"
julia> a
2
```
"""
macro tau(sim, check::Symbol, val::Union{Number, QuoteNode}, m::Module=Main)
    return :( SimFunction(tau, $sim, $check, $val, m=$m) )
end
macro tau(check::QuoteNode, val::Union{Number, QuoteNode}, m::Module=Main)
    return :( SimFunction(tau, $check, $val, m=$m) )
end

"""
```
@val(a::Union{Number, QuoteNode}, check::QuoteNode, b::Union{Number, QuoteNode}, m::Module=Main)
@val a check b m
@val a check b
```
Create a Simfunction comparing two values a and b or two symbolic variables
:a and :b. The comparison operator must be given symbolically, e.g. `:≤`.

# Arguments
- `a,b::Union{Number, QuoteNode}`: a number or a symbol like `:a`
- `check::QuoteNode`: a comparison operator as a symbol like `:≤`
- `, m::Module=Main`: a module scope for evaluation of given symbolic variables

!!! note
    If you give @val as argument(s) to a function, you must enclose it/them
    in parentheses ( @val ... ) or e.g. ( (@tau ...), (@val ...) )!

# Examples
```@jldoctest
julia> using Simulate

julia> @val 1 :≤ 2
SimFunction(val, (1, :≤, 2), Base.Iterators.Pairs(:m => Main))
julia> Simulate.simExec(@val 1 :≤ 2)
true
julia> a = 1
1
julia> Simulate.simExec(@val :a :≤ 2)
true
julia> event!(:(a += 1), ((@tau :>= 3), (@val :a :<= 3))) # a conditional event
0.0
julia> run!(𝐶, 5)
"run! finished with 0 clock events, 500 sample steps, simulation time: 5.0"
julia> a
2
```
"""
macro val(a::Union{Number, QuoteNode}, check::QuoteNode, x::Union{Number, QuoteNode}, m::Module=Main)
    return :( SimFunction(val, $a, $check, $x, m=$m) )
end
