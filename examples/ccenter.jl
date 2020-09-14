#
# A-B Call Center problem
#
using DiscreteEvents, Distributions, Random

mutable struct Caller
    id::Int
    t₁::Float64  # arrival time
    t₂::Float64  # beginning of service time
    t₃::Float64  # end of servive time
end

mutable struct Server
    id::Int
    S::Distribution  # service time distribution
    tbusy::Float64   # cumulative service time
end

function serve(c::Clock, s::Server, input::Channel, output::Vector{Caller}, limit::Int)
    call = take!(input)           # take a call
    call.t₂ = c.time              # record the beginning of service time
    delay!(c, s.S)                # delay for service time
    call.t₃ = c.time              # record the end of service time 
    s.tbusy += call.t₃ - call.t₂  # log service time
    push!(output, call)           # hang up
    call.id ≥ limit && stop!(c) 
end

function arrive(c::Clock, input::Channel, count::Vector{Int})
    count[1] += 1
    put!(input, Caller(count[1], c.time, 0.0, 0.0))
end

Random.seed!(123)
const N = 1000
const M_arr = Exponential(2.5)
const M_a   = Exponential(3)
const M_b   = Exponential(4)
count = [0]

clock = Clock()
input = Channel{Caller}(Inf)
output = Caller[]
s1 = Server(1, M_a, 0.0)
s2 = Server(2, M_b, 0.0)
# process!(clock, Prc(1, serve, s1, input, output, N))
# process!(clock, Prc(2, serve, s2, input, output, N))
# event!(clock, fun(arrive, clock, input, count), every, M_arr)
# run!(clock, 5000)
@process serve(clock, s1, input, output, N)
@process serve(clock, s2, input, output, N)
@event arrive(clock,input,count) every M_arr
@run! clock 5000

# using Plots
# wt = [c.t₂ - c.t₁ for c in output]
# plot(wt, title="A-B-Call center ", xlabel="callers", ylabel="waiting time [min]", legend=false)
# savefig("ccenter.png")