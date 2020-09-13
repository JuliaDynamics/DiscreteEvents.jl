"""
    @proceses

Create a process from a function.

Note: the first arg to the function being passed must be an AbstractClock
"""
macro process(id, expr)
    expr.head != :call && error("Expression is not a function call.")
    f = expr.args[1] #extract function passed
    c = expr.args[2] #first function arg must be an AbstractClock
    args = expr.args[3:end] #extract other function args
    p = :(Prc($id, $f, $(args...))) #create Prc struct
    esc(:(process!($c,$p))) #execute process!
end

"""
    @event

Schedule an event.

Note: if 3 arguments are passed after the function being called,
    the third one is assumed to be the keyword argument `n`.
"""
macro event(expr, args...)
    expr.head != :call && error("Expression is not a function call.")
    f = expr.args[1] #extract function passed
    c = expr.args[2] #first function arg must be an AbstractClock
    fargs = expr.args[2:end] #extract other function args
    ex = :(fun($f, $(fargs...))) #create Action
    if length(args) <= 2 
        esc(:(event!($c, $ex, $(args...)))) #execute event!
    else
        esc(:(event!($c, $ex, $(args[1:2]...), n = $args[end]))) #execute event!
    end
end

"""
    @run!

Run a simulation for a given duration.
"""
macro run!(clk, duration)
    return esc(:(run!($clk, $duration)))
end