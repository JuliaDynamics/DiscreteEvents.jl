using DiscreteEvents, Printf, Distributions, Random

Random.seed!(123)  # set random number seed
const μ = 1/3       # service rate
const λ = 0.9       # arrival rate
count = [0]         # a job counter

# describe the server process
function serve(clk::Clock, id::Int, input::Channel, output::Channel, X::Distribution)
    job = take!(input)
    print(clk, @sprintf("%6.3f: server %d serving customer %d\n", tau(clk), id, job))
    delay!(clk, X)
    print(clk, @sprintf("%6.3f: server %d finished serving %d\n", tau(clk), id, job))
    put!(output, job)
end

# model the arrivals
function arrive(c::Clock, input::Channel, cust::Vector{Int})
    cust[1] += 1
    @printf("%6.3f: customer %d arrived\n", tau(c), cust[1])
    put!(input, cust[1])
end

clock = Clock()   # create a clock
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
for i in 1:3      # start three server processes
    process!(clock, Prc(serve, i, input, output, Exponential(1/μ)))
end
# create a repeating event for 10 arrivals
event!(clock, fun(arrive, clock, input, count), every, Exponential(1/λ), n=10)
run!(clock, 20)   # run the clock
