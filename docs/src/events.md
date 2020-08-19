# Events

```@meta
CurrentModule = DiscreteEvents
```

Events are computations ``\,α,β,γ,...\,`` at times ``\,t_1,t_2,t_3,...`` Those computations are called *actions*.

## Actions

Actions are Julia functions or expressions to be executed later:

```@docs
Action
fun
```

!!! warning "Evaluating expressions is slow!"

    `Expr` should be avoided. You will get a one time warning if you use them. They can be replaced easily by `fun`s or function closures. They are evaluated at global scope in Module `Main` only. Other modules using `DiscreteEvents` cannot use `Expr` in events and have to use functions.

Actions can be combined into tuples:

```@repl events
using DiscreteEvents
a = 1
println(a) isa Action        # a function call is not an action
fun(println, a) isa Action   # wrapped in a fun it is an action
isa(()->println(a), Action)  # an anonymous function
:(println(a)) isa Action     # an expression
(()->println(a), fun(println, a), :(println(a))) isa Action # a tuple of them
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

## Events and variables

Actions often depend on data or modify it. The data may change between the definition of an action and its later execution. If an action uses a *mutable variable* like an array or a mutable struct, it gets current data at event time and it is fast. If the action modifies the data, this is the best way to do it:

```@repl events
using DiscreteEvents
a = [1]                  # define a mutable variable a
f(x; y=2) = (x[1] += y)  # define a function f
ff = fun(f, a);          # enclose f and a in a fun ff
a[1] += 1                # modify a
ff()                     # execute ff
a[1]                     # a has been modified correctly
```

If for some reason and against [better advise](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-global-variables-1) you want to work with global variables, there are several ways to deal with them:

```@repl events
g(x; y=1) = x+y                 # define a function g
x = 1;                          # define x = 1
gg = fun(g, :x, y=2);           # pass x as a symbol to g
x += 1                          # increment x
2
gg()                            # now g gets a current x and gives a warning
hh = fun(g, fun(()->x), y=3);   # reference x with an anonymous fun
x += 1                          # x becomes 3
hh()                            # g gets again a current x
ii = fun(g, ()->x, y=4);        # reference x with an anonymous function
x += 1                          # x becomes 4
ii()                            # g gets an updated x
```

If you want to modify a global variable, you have to use the `global` keyword inside your function.
