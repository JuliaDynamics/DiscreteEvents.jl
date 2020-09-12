#
# inventory control problem
#
using DiscreteEvents, Distributions, Random

mutable struct Station
    q::Float64           # fuel amount
    t::Vector{Float64}   # time vector
    qt::Vector{Float64}  # fuel/time vector
    cs::Int              # customers served
    cl::Int              # customers lost
    qs::Float64          # fuel sold
    ql::Float64          # lost sales
end

function customer(c::Clock, s::Station, X::Distribution)
    function fuel(s::Station, x::Float64)
        s.q -= x             # take x from tank
        push!(s.t, c.time)   # record time, amount, customer, sale
        push!(s.qt, s.q)
        s.cs += 1            
        s.qs += x
    end

    x = rand(X)              # calculate demand
    if s.q ≥ x               # demand can be met
        fuel(s, x)
    elseif s.q ≥ a           # only partially in stock
        s.ql += x - s.q      # count the loss
        fuel(s, s.q)         # give em all we have
    else
        s.cl += 1            # count the lost customer
        s.ql += x            # count the lost demand
    end
end

function replenish(c::Clock, s::Station, Q::Float64)
    if s.q < a
        push!(s.t, c.time)
        push!(s.qt, s.q)
        s.q += Q
        push!(s.t, c.time)
        push!(s.qt, s.q)
    end
end

Random.seed!(123)
const λ = 0.5      # ~ every two minutes a customer
const ρ = 1/180    # ~ every 3 hours a replenishment truck
const μ = 30       # ~ mean demand per customer 
const σ = 10       #   standard deviation
const a = 5        #   minimum amount 
const Q = 6000.0   # replenishment amount
const M₁ = Exponential(1/λ)  # customer arrival time distribution
const M₂ = Exponential(1/ρ)  # replenishment time distribution
const X = TruncatedNormal(μ, σ, a, Inf)  # demand distribution

clock = Clock()
s = Station(Q, Float64[0.0], Float64[Q], 0, 0, 0.0, 0.0)
# event!(clock, fun(replenish, clock, s, Q), every, M₂)
# event!(clock, fun(customer, clock, s, X), every, M₁)
# println(run!(clock, 5000))
@event clock fun(replenish, clock, s, Q) every M₂
@event clock fun(customer, clock, s, X) every M₁
println(@run! clock 5000)

@show fuel_sold = s.qs;
@show loss_rate = s.ql/s.qs;
@show served_customers = s.cs;
@show lost_customers = s.cl;

# using Plots
# plot(s.t, s.qt, title="Filling Station", xlabel="time [min]", ylabel="inventory [L]", legend=false)
# savefig("invctrl.png")
