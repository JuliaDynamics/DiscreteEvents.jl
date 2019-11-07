#
# routines for handling functions as processes
#

"""
    process!(sim::Clock, p::SimProcess)

Register a `SimProcess` to a clock and return the `id` it was registered with.
It can then be found under `sim.processes[id]`.
"""
function process!(sim::Clock, p::SimProcess)
    id = p.id
    while haskey(sim.processes, id)
        if isa(id, Float64)
            id = nextfloat(id)
        elseif isa(id, Int)
            id += 1
        elseif isa(id, String)
            s = split(id, "#")
            id = length(s) > 1 ? chop(id)*string(s[end][end]+1) : id*"#1"
        else
            error("process id $id is duplicate, cannot convert!")
        end
    end
    sim.processes[id] = p
    p.id = id
end

"""
    loop(p::SimProcess)

Put a `SimProcess` in a loop, which can be broken by a `SimException`.
"""
function loop(p::SimProcess)
    while true
        try
            p.func(p.in, p.out, p.arg...; p.kw...)
        catch exc
            if isa(exc, SimException)
                exc.ev == Stop() ? break : nothing
            end
            rethrow(exc)
        end
    end
end

"""
    startup!(p::SimProcess)

Start a `SimProcess` as a task in a loop.
"""
function startup!(p::SimProcess)
    p.task = @async loop(p)
    p.state = Idle()
    yield() # let the process start
end

step!(p::SimProcess, ::Undefined, ::Start) = startup!(p)

step!(p::SimProcess, ::Halted, ::Resume) = startup!(p)

function step!(p::SimProcess, ::Idle, ::Stop)
    schedule(p.task, SimException(Stop()))
    yield()
    p.state = Halted()
end

"""
    delay!(sim::Clock, t::Number)

delay the calling process or function for a time `t` on the clock `sim`.

Other methods:

- `delay!(t::Number)`: equivalent to `delay!(𝐶, t)`
"""
function delay!(sim::Clock, t::Number)
    c = Channel(0)
    event!(sim, SimFunction(put!, c, t), after, t)
    take!(c)
end
delay!(t::Number) = delay!(𝐶, t)

function step!(sim::Clock, ::Idle, ::Start)
    for p ∈ values(sim.processes)
        startup!(p)
    end
end

"""
    start!(sim::Clock)

Start all registered processes in a clock.
"""
start!(sim::Clock) = step!(sim, sim.state, Start())

"""
    stop!(p::SimProcess)

Stop a `SimProcess` by throwing a `SimException` to it.
"""
stop!(p::SimProcess)
