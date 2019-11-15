#
# Utilities
#

"""
```
tauis(sim::Clock, check::Symbol, x::Union{Number,Symbol}; m::Module=Main)
tauis(check::Symbol, x::Union{Number,Symbol}; m::Module=Main)
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

julia> tauis(:>=, 1)
false
julia> tauis(:<, 1)
true
julia> a = 1
1
julia> tauis(:<=, :a)
true
```
"""
tauis(sim::Clock, check::Symbol, x::Union{Number,Symbol}; m::Module=Main) =
        x isa Number ? eval(check)(τ(sim), x) : eval(check)(τ(sim), Core.eval(m, x))
tauis(check::Symbol, x::Union{Number,Symbol}; m::Module=Main) = tauis(𝐶, check, x, m=m)

"""
```
checkval(a::Union{Number, Symbol}, check::Symbol, x::Union{Number, Symbol}; m::Module=Main)
```
Compare two variables or numbers.

# Examples
```@jldoctest
julia> using Simulate

julia> checkval(1, :<=, 2)
true
julia> a = 1
1
julia> checkval(:a, :<=, 2)
true
```
"""
function checkval(a::Union{Number, Symbol}, check::Symbol, x::Union{Number, Symbol};
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

!!! note
    keyword arguments don't work with this macro, use SF instead.
"""
macro SF(f::Symbol, arg...)
    return :( SimFunction( $f, $(arg...) ) )
end

"""
```
@SP(id, f::Symbol, input::Channel, output::Channel, arg...)
@SP id f input output arg...
```
create a `SimFunction` from arguments f, arg...

!!! note
    keyword arguments don't work with this macro, use SF instead.
"""
macro SP(id, f::Symbol, input::Channel, output::Channel, arg...)
    return :( SimProcess($id, $f, $input, $output, $(arg...) ) )
end

"""
```
@tauis(sim::Clock, check::Symbol, val::Number)
@tauis sim check val
@tauis(check::Symbol, val::Number)
@tauis check val
```
create a `SimFunction` comparing current simulation time with a given value.
The comparison operator must be given as a symbol like `:<`.

# Examples
```jldoctest
julia> using Simulate

julia> s = @tauis :≥ 100
SimFunction(Simulate.tauis, (:≥, 100), Base.Iterators.Pairs(:m => Main))
julia> Simulate.simExec(s)
false
julia> Simulate.simExec(@tauis < 100)
ERROR: syntax: "<" is not a unary operator
julia> Simulate.simExec(@tauis :< 100)
true
julia> Simulate.simExec(@tauis :>= 100)
false
julia> a = 1
1
julia> Simulate.simExec(@tauis :< :a)
true
```
"""
macro tauis(sim, check::Symbol, val::Union{Number, QuoteNode}, m::Module=Main)
    return :( SimFunction(tauis, $sim, $check, $val, m=$m) )
end
macro tauis(check::QuoteNode, val::Union{Number, QuoteNode}, m::Module=Main)
    return :( SimFunction(tauis, $check, $val, m=$m) )
end

"""
```
@checkval(a::Union{Number, QuoteNode}, check::QuoteNode, b::Union{Number, QuoteNode}, m::Module=Main)
@checkval a check b m
@checkval a check b
```
Create a Simfunction comparing two values a and b or two symbolic variables
:a and :b. The comparison operator must be given symbolically, e.g. `:≤`.

# Arguments
- `a,b::Union{Number, QuoteNode}`: a number or a symbol like `:a`
- `check::QuoteNode`: a comparison operator as a symbol like `:≤`
- `, m::Module=Main`: a module scope for evaluation of given symbolic variables

# Examples
```@jldoctest
julia> using Simulate

julia> @checkval 1 :≤ 2
SimFunction(checkval, (1, :≤, 2), Base.Iterators.Pairs(:m => Main))
julia> Simulate.simExec(@checkval 1 :≤ 2)
true
julia> a = 1
1
julia> Simulate.simExec(@checkval :a :≤ 2)
true
```
"""
macro checkval(a::Union{Number, QuoteNode}, check::QuoteNode, x::Union{Number, QuoteNode}, m::Module=Main)
    return :( SimFunction(checkval, $a, $check, $x, m=$m) )
end
