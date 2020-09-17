# Events

```@meta
CurrentModule = DiscreteEvents
```

Events are computations ``\,α,β,γ,...\,`` at times ``\,t_1,t_2,t_3,...`` We call those computations *actions*.

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
isa(()->println(a), Action)  # an anonymous function
:(println(a)) isa Action     # an expression
(()->println(a), fun(println, a), :(println(a))) isa Action # a tuple of them
```

### Expressions and Symbols

Expressions too are Actions. Also you can pass symbols to `fun` to delay evaluation of variables. `Expr`s and `Symbol`s are evaluated at global scope in Module `Main` only. This is a user convenience feature. Other modules using `DiscreteEvents` cannot use them in events and have to use functions.

!!! warning "Evaluating expressions is slow!"

    Usage of `Expr` or `Symbol` will generate a one time warning. You can replace them easily with `fun`s or function closures. 

## Timed Events

Actions can be scheduled as events at given times:

```@docs
Timing
event!(::CL,::A,::U)  where {CL<:AbstractClock,A<:Action,U<:Number}
```

## Conditional Events

Actions can be scheduled as events under given conditions:

```@docs
event!(::T,::A,::C) where {T<:AbstractClock,A<:Action,C<:Action}
```

!!! note "Use inequalities to express conditions"

    Conditions should be expressed with inequalities like <, ≤, ≥, > rather than with equality == in order to make sure that they can be detected, e.g. `tau() ≥ 100` is preferable to `tau() == 100`.

## The @event Macro

If a function has a clock as its first argument, you can use the `@event` macro to schedule it. This wraps it into a `fun` closure and then calls `event!` with it.

```@docs
@event
```

### Use Cases

Currently `@event` supports the following use cases (it accepts a number or a distribution as time `t` argument):

```julia
@event f(clk, a, b) at t        # schedule f(clk, a, b) at time t
@event f(clk, a, b) t           # the same
@event f(clk, a, b) after t     # schedule f(clk, a, b) after t time units
@event f(clk, a, b) every t     # schedule it every t unit
@event f(clk, a, b) every t 10  # schedule it every t unit for 10 times
@event f(clk, a, b) g(c)        # schedule it on condition g(c)
@event f(clk, a, b) :a ≥ 5      # schedule it on condition a ≥ 5
@event f(clk, a, b) ()-> a≥5 && tau(clk)≥8  # on condition of an anonymous function
```

The first call gets expanded to `event!(clk, fun(f, clk, a, b), after, 10)`.

Note: the `@event` macro doesn't accept keyword arguments. If you want to use `event!` with keyword arguments, you must use it explicitly.

## Continuous Sampling

Actions can be registered for sampling and are then executed "continuously" at each clock increment Δt. The default clock sample rate Δt is 0.01 time units.

```@docs
sample_time!
periodic!
@periodic
```

## Events and Variables

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

There are good [reasons to avoid global variables](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-global-variables-1) but if you want to work with them, you can do it in several ways:

```@repl events
g(x; y=1) = x+y                 # define a function g
x = 1;                          # define a global variable x = 1
gg = fun(g, :x, y=2);           # pass x as a symbol to g
x += 1                          # increment x
2
gg()                            # now g gets a current x and gives a warning
hh = fun(g, fun(()->x), y=3);   # reference x with an anonymous fun
x += 1                          # increment x
hh()                            # g gets again a current x
ii = fun(g, ()->x, y=4);        # reference x with an anonymous function
x += 1                          # increment x
ii()                            # g gets an updated x
```

To modify a global variable, you have to use the `global` keyword inside your function.

## Events with Time Units

Timed events can be scheduled with time units. Times are converted to the clock's time unit.

```@repl events
using Unitful
import Unitful: s, minute, hr
c = Clock()
event!(c, fun(f, a), 1s)
setUnit!(c, s)
event!(c, fun(f, a), 1minute)
event!(c, fun(f, a), after, 1hr)
```
