#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
# Benchmark adopted from the dicegame.ipynb example
#

using Simulate, Distributions, Random, BenchmarkTools
import Dates.now

mutable struct Worker
    nr::Int64              # worker number
    input::Channel
    output::Channel
    dist::Distribution     # distribution of processing time
    retard::Float64        # worker retard factor, 1: no retardation, >1: retardation
    done::Int64            # number of finished items

    Worker(nr, input, output, dist, perform) = new(nr, input, output, dist, 1/perform, 0)
end

function work(clk::Clock, w::Worker)
    job = take!(w.input)
    delay!(clk, rand(w.dist) * w.retard)
    put!(w.output, job)
    w.done += 1
end

function setup( n::Int64, mw::Int64,
                    vp::Distribution, vw::Distribution;
                    d=1000, seed=1234, jobs=1000)
    global clk = Clock()
    Random.seed!(seed)                  # seed random number generator
    global C = [Channel{Int64}(mw) for i in 1:n+1] # create n+1 channels with given buffer sizes
    C[1] = Channel{Int64}(Inf)                 # unlimited sizes for channels 1 and n+1
    C[n+1] = Channel{Int64}(Inf)
    j = reverse(Array(1:(n-1)*2))
    for i in n:-1:2                     # seed channels 2:(n-1) each with 2 inventory items
        C[i].sz_max > 0 ? put!(C[i], j[(i-1)*2]) : nothing
        C[i].sz_max > 1 ? put!(C[i], j[(i-1)*2-1]) : nothing
    end
    for i in ((n-1)*2+1):jobs           # put other jobs into channel 1
        put!(C[1], i)
    end

    wp = rand(vw, n)                    # calculate worker performance
    global W = [Worker(i, C[i], C[i+1], vp, wp[i]) for i in 1:n]
    for i in 1:n
        process!(clk, Prc(i, work, W[i]))
    end
end

# first run to compile
setup(5, 5, Gamma(10,1/10), Normal(1,0), jobs=1200)
run!(clk, 1000)

# then take measurements
println(now())
@time onthread(2) do; setup(5, 5, Gamma(10,1/10), Normal(1,0), jobs=1200); end
println(@time onthread(2) do; run!(clk, 1000); end)
println("events=", clk.evcount, " throughput:", length(C[end].data))

t = run(@benchmarkable onthread(2) do; run!(clk, 1000); end setup=onthread(2) do; setup(5, 5, Gamma(10,1/10), Normal(1,0), jobs=1200); end  evals=1 seconds=15.0 samples=50)
