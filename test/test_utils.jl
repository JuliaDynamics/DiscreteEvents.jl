#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
using DiscreteEvents, Distributions, Random, .Threads, Test

num_customers = 10   # total number of customers generated
num_servers = 2      # number of servers
μ = 1.0 / 2          # service rate
λ = 0.9              # arrival rate
arrival_dist = Exponential(1/λ)  # interarrival time distriubtion
service_dist = Exponential(1/μ); # service time distribution

# describe the server process
function server(clk::Clock, id::Int, input::Channel, output::Channel, service_dist::Distribution)
    job = take!(input)
    # _bench[end] || now!(clk, ()->@printf("%5.3f: server %d serving customer %d\n", tau(clk), id, job))
    delay!(clk, rand(service_dist))
    # _bench[end] || now!(clk, ()->@printf("%5.3f: server %d finished serving %d\n", tau(clk), id, job))
    put!(output, job)
end

# model arrivals
function arrivals(clk::Clock, queue::Channel, num_customers::Int, arrival_dist::Distribution)
    for i = 1:num_customers # initialize customers
        delay!(clk, rand(arrival_dist))
        put!(queue, i)
        # _bench[end] || now!(clk, ()->@printf("%5.3f: customer %d arrived\n", tau(clk), i))
    end
end

function run_model(arrival_dist, service_dist, num_customers, num_servers, t)
    onthread(2) do
        Random.seed!(8710)   # set random number seed for reproducibility
        clock = Clock()
        for i in 1:num_servers
            process!(clock, Prc(i, server, i, input, output, service_dist))
        end
        process!(clock, Prc(0, arrivals, input, num_customers, arrival_dist), 1)
        run!(clock, t)
    end
end

# create a matrix of random numbers with n row and 
# a column of random numbers generated on each thread
function prand(n::Int)
    rd = zeros(Int64, n, nthreads())
    @threads for i in 1:nthreads()
        rd[:,i] = rand(Int64, n)
    end
    return rd
end

input = Channel{Int}(Inf)
output = Channel{Int}(Inf)

if (VERSION ≥ v"1.3") && (nthreads() > 1)
    println("... testing utilities ...")
    run_model(arrival_dist, service_dist, 10, 2, 20)
    @test length(output) == 10

    pseed!(123)
    x = prand(1)
    @test x != prand(1)
    pseed!(123)
    @test x == prand(1)
end

