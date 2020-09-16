#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Hector Perez, Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

"""
    @process f(arg...) [cycles]

Create a process from a function `f(arg...)`.

Wrap a function and its arguments in a [`Prc`](@ref) and start it with 
[`process!`](@ref).

# Arguments
- `f`: a function,
- `arg...`: arguments, the first argument must be an AbstractClock,
- `cycles::Int`: the number of cycles, `f` should run.

# Returns
- an `Int` process id.
"""
macro process(expr, args...)
    @assert expr isa Expr && expr.head == :call "1st term is not a function call!"
    f = expr.args[1] #extract function passed
    c = expr.args[2] #first function arg must be an AbstractClock
    fargs = expr.args[3:end] #extract other function args
    p = :(Prc($f, $(fargs...))) #create Prc struct
    if isempty(args)
        esc(:(process!($c,$p))) #execute process!
    else
        cycles = args[1] #extract cycle
        esc(:(process!($c,$p,$cycles))) #execute process!
    end
end

"""
    @event f(arg...) T t [n]

Schedule a function `f(arg...)` as an event to a clock.

# Arguments
- `f`: function to be executed at event time,
- `arg...`: its arguments, the first argument must be a clock,
- `T`: a [`Timing`](@ref) (at, after, every),
- `n`: passed as keyword `n` to `event!`.
"""
macro event(expr, args...)
    @assert expr isa Expr && expr.head == :call "1st term is not a function call!"
    f = expr.args[1] #extract function passed
    c = expr.args[2] #first function arg must be an AbstractClock
    fargs = expr.args[2:end] #extract other function args
    ex = :(fun($f, $(fargs...))) #create Action
    if length(args) == 3 
        esc(:(event!($c, $ex, $(args[1:2]...), n = $(args[3])))) #execute event!
    else
        esc(:(event!($c, $ex, $(args...)))) #execute event!
    end
end

"""
```
@event f(farg...) c(carg...)
@event f(farg...) ca
```
Schedule a function `f(farg...)` as a conditional event to a clock.

# Arguments
- `f`: function to be executed at event time,
- `farg...`: its arguments, the first argument must be a clock,
- `c`: function to be evaluated at the clock's sample rate, if it
    returns true, the event is triggered,
- `carg...`: arguments to c,
- `ca`: an anyonymous function of the form `()->...` to be evaluated 
    at the clock's sample rate, if it returns true, the event
    is triggered.
"""
macro event(expr, cond)
    @assert expr isa Expr && expr.head == :call "1st term is not a function call!"
    f1 = expr.args[1] 
    c = expr.args[2] 
    f1args = expr.args[2:end] 
    ex1 = :(fun($f1, $(f1args...))) 
    if cond isa Expr 
        if cond.head == :call
            f2 = cond.args[1] 
            f2args = cond.args[2:end] 
            ex2 = :(fun($f2, $(f2args...))) 
        elseif cond.head == :->
            ex2 = :(()->$(cond.args...))
        end
        esc(:(event!($c, $ex1, $ex2)))
    else    # assume it should be a simple timed event
        esc(:(event!($c, $ex1, $cond))) 
    end
end

"""
    @periodic f(arg...) [Δt]

Register a function `f(arg...)` for periodic execution at the 
clock`s sample rate.

# Arguments
- `f`: function to be executed periodically,
- `arg...`: its arguments, the first argument must be a clock,
- `Δt`: for setting the clock's sample rate.
"""
macro periodic(expr, args...)
    @assert expr isa Expr && expr.head == :call "1st term is not a function call!"
    f = expr.args[1]
    c = expr.args[2]
    fargs = expr.args[2:end]
    ex = :(fun($f, $(fargs...)))
    if length(args) == 3 
        esc(:(periodic!($c, $ex, $(args[1:2]...), $(args[3])))) #execute event!
    else
        esc(:(periodic!($c, $ex, $(args...)))) #execute event!
    end
end

"""
```
@delay clk Δt
@delay clk until t
```
Delay a process on a clock `clk` for a time interval `Δt` or until
a time `t`.
"""
macro delay(clk, delay...)
    esc(:(delay!($clk, $(delay...))))
end

"""
    @wait clk f(arg...)

Conditionally wait on a clock `clk` until `f(arg...)` returns true.
"""
macro wait(clk, expr)
    expr.head != :call && error("2nd term is not a function call.")
    f = expr.args[1]
    fargs = expr.args[2:end]
    ex = :(fun($f, $(fargs...)))
    esc(:(wait!($clk, $ex)))
end

"""
    @run! clk t

Run a clock `clk` for a duration `t`. 
"""
macro run!(clk, duration)
    esc(:(run!($clk, $duration)))
end