"""
    @proceses

Register a process to a clock.
"""
macro process(c, p, cycles=Inf)
    return esc(:(process!($c, $p, $cycles)))
end

"""
    @event

Schedule an event for a given time `t`.
"""
macro event(clk, ex, t) 
    # Cases: 1 - 2
    # t is Number or Distribution
    return esc(:(event!($clk, $ex, $t)))
end

macro event(clk, ex, t, cy, n) 
    # Cases: 3 - 5 (when n is specified)
    # t and cy are Numbers or Distributions
    return esc(:(event!($clk, $ex, $t, $cy; n = $n)))
end

macro event(clk, ex, T, t) 
    # Cases: 3 - 7
    # T is timing or Numbers or Distributions
    # t is Number or Distribution
    return esc(:(event!($clk, $ex, $T, $t)))
end

"""
    @run!

Run a simulation for a given duration.
"""
macro run!(clk, duration)
    return esc(:(run!($clk, $duration)))
end