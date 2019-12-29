using Simulate, BenchmarkTools, Random
import Dates.now
res = Dict(); # results dictionary

function take(id::Int64, ch::Channel, step::Int64, qpi::Array{Float64,1})
    if isready(ch)
        take!(ch)                                            # take something from common channel
        event!(SF(put, id, ch, step, qpi), after, rand())    # timed event after some time
    else
        event!(SF(take, id, ch, step, qpi), SF(isready, ch)) # conditional event until channel is ready
    end
end

function put(id::Int64, ch::Channel, step::Int64, qpi::Array{Float64,1})
    put!(ch, 1)
    qpi[step] += (-1)^(id+1)/(2id -1)      # Machin-like series (slow approximation to pi)
    step > 3 || take(id, ch, step+1, qpi)
end

function setup(n::Int)                     # a setup he simulation
    reset!(𝐶)
    Random.seed!(123)
    global ch = Channel{Int64}(32)  # create a channel
    global qpi = zeros(4)
    si = shuffle(1:n)
    for i in 1:n
        take(si[i], ch, 1, qpi)
    end
    for i in 1:min(n, 32)
        put!(ch, 1) # put first tokens into channel 1
    end
end

# first run to compile
setup(250)
run!(𝐶, 500)

# then take measurements
println(now())
@time setup(250)
println(@time run!(𝐶, 500))
println("result=", sum(qpi))

t = run(@benchmarkable run!(𝐶, 500) setup=setup(250) evals=1 seconds=15.0 samples=50)
