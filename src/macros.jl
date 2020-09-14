"""
    @proceses

Create a process from a function.

Note: the first arg to the function being passed must be an AbstractClock
"""
macro process(expr, args...)
    expr.head != :call && error("Expression is not a function call.")
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
    if length(args) == 3 
        esc(:(event!($c, $ex, $(args[1:2]...), n = $args[3]))) #execute event!
    else
        esc(:(event!($c, $ex, $(args...)))) #execute event!
    end
end

"""
    @delay

Delay a process.
"""
macro delay(clk, delay...)
    esc(:(delay!($clk, $(delay...))))
end

"""
    @wait

Delay a process until a condition has been met.
"""
macro wait(clk, cond)
    exc(:(wait!($clk, $cond)))
end

"""
    @run!

Run a simulation for a given duration.

Takes two arguments: clock and duration.
"""
macro run!(clk, duration)
    esc(:(run!($clk, $duration)))
end