using Simulate, Distributions

function people(sim::Simulation, β::Float64, queue::Array{Int64,1}, clerk::Resource)
    i = 1
    while true
        Δt = rand(Exponential(β))
        yield(Timeout(sim, Δt))
        @process customer(sim, i, queue, clerk)
        i += 1
    end
end

function customer(sim::Simulation, n::Int64, queue::Array{Int64,1}, clerk::Resource)
    wt = 0
    if length(queue) ≥ 5
        wt = -1
        logevent(sim, n, queue, "leaves - queue is full!", wt)
        return
    else
        arrivaltime = now(sim)
        logevent(sim, n, queue, "enqueues", wt)
        push!(queue, n)
        yield(Request(clerk))
        shift!(queue)
        logevent(sim, n, queue, "now being served", wt)
        Δt = rand(DiscreteUniform(1, 5)) + randn()*0.2
        yield(Timeout(sim, Δt))
        yield(Release(clerk))
        wt = now(sim)-arrivaltime
        logevent(sim, n, queue, "leaves", wt)
    end
end

simlog = newlog()
ev = Dict("customer"=>0, "queue_len"=>0, "status"=>"", "wait_time"=>0)
dict2log(simlog, ev)

function logevent(sim::Simulation, customer, queue, status, wt)
    ev["customer"] = customer
    ev["queue_len"] = length(queue)
    ev["status"] = status
    if wt != 0
        ev["wait_time"] = wt
    end
    lognow(sim, simlog)
end

srand(1234)  # seed random number generator for reproducibility
queue = Int64[]

sim = Simulation()
clerk = Resource(sim, 1)
@process people(sim, 3.333, queue, clerk)
run(sim, 600)
d = log2df(simlog)                   # logged data to dataframe
println(queue, " yet in queue")
tail(d)
