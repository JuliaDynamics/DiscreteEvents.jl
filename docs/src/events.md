# Events

```@meta
CurrentModule = DiscreteEvents
```

In `DiscreteEvents` events can be considered as computations ``\,α,β,γ,...\,`` happening at times ``\,t_1,t_2,t_3,...`` Those computations are called *actions*.

## Actions

Actions are Julia functions or expressions to be executed later:

```@docs
Action
fun
```

Actions can be combined into tuples:

```@repl events
using DiscreteEvents
a = 1
println(a) isa Action        # a function call is not an action
fun(println, a) isa Action   # wrapped in a fun it is an action
isa(()->println(a), Action)
:(println(a)) isa Action
(()->println(a), fun(println, a), :(println(a))) isa Action
```

Actions can be scheduled for execution

1. at given clock times and
2. under specified conditions.

## Timed events

Actions can be scheduled as events at given times:

```@docs
Timing
event!(::CL,::A,::U)  where {CL<:AbstractClock,A<:Action,U<:Number}
```

## Conditional events

Actions can be scheduled as events under given conditions:

```@docs
event!(::T,::A,::C) where {T<:AbstractClock,A<:Action,C<:Action}
```

!!! note "Use inequalities to express conditions"

    For conditions you should prefer inequalities like <, ≤, ≥, > to equality == in order to make sure that a condition can be detected, e.g. `tau() ≥ 100` is preferable to `tau() == 100`.

## Continuous sampling

Actions can be registered for sampling and are then executed "continuously" at each clock increment Δt. The default clock sample rate Δt is 0.01 time units.

```@docs
sample_time!
periodic!
```
