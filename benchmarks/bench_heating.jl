#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
# Benchmark adopted from the house_heating.ipynb example
#

using Simulate, Random, Distributions, Statistics, BenchmarkTools
import Dates.now

const Th = 40     # temperature of heating fluid
const R = 1e-6    # thermal resistance of room insulation
const α = 2e6     # represents thermal conductivity and capacity of the air
const β = 3e-7    # represents mass of the air and heat capacity
const Δt = 1//60  # update every minute

mutable struct House
    Te::Float64   # environment temperature
    Tr::Float64   # room temperature
    heating::Bool # heating on or off
    η::Float64    # efficiency factor reducing R if doors or windows are open
    rng::MersenneTwister       # random number generator
    datTr::Vector{Float64}     # room temperature data
end

Δte(t, t1, t2) = cos((t-10)*π/12) * (t2-t1)/2  # change of a sinusoidal Te

function Δtr(h::House)                         # calculate room temperature change
    Δqc = (h.Tr - h.Te)/(R * h.η)                # cooling rate
    Δqh = h.heating ? α * (Th - h.Tr) : 0    # heating rate
    return β * (Δqh - Δqc)
end

function setTemperatures!(h::House, t1=8, t2=20)               # change the temperatures
    h.Te += Δte(tau(), t1, t2) * 2π/1440 + rand(h.rng, Normal(0, 0.1))
    h.Tr += Δtr(h) * Δt
    push!(h.datTr, h.Tr)       # append room temperature data
end

function switch!(h::House, t1=20, t2=23)                       # simulate the thermostat
    if h.Tr ≥ t2
        h.heating = false
        event!(fun(switch!, h, t1, t2), fun((h, x)-> h.Tr ≤ x, h, t1))  # setup a conditional event
        # event!(fun(switch, t1, t2), @val :Tr :≤ t1)  # setup a conditional event
    elseif h.Tr ≤ t1
        h.heating = true
        event!(fun(switch!, h, t1, t2), fun((h, x)-> h.Tr ≥ x, h, t2))  # setup a conditional event
        # event!(fun(switch, t1, t2), @val :Tr :≥ t2)  # setup a conditional event
    end
end

function people!(clk::Clock, h::House)
    delay!(clk, 6 + rand(Normal(0, 0.5)))         # sleep until around 6am
    sleeptime = 22 + rand(Normal(0, 0.5))    # calculate bed time
    while tau(clk)%24 < sleeptime
        h.η = rand()                         # open door or window
        delay!(clk, 0.1 * rand(Normal(1, 0.3)))   # for some time
        h.η = 1.0                            # close it again
        delay!(clk, rand())
    end
end

function setup()
    reset!(𝐶)                                      # reset the clock
    global house = House(11, 20, false, 1.0, MersenneTwister(122), Float64[])
    Random.seed!(1234)

    for i in 1:2                              # put 2 people in the house
        process!(Prc(i, people!, house))       # run processes
    end
    periodic!(fun(setTemperatures!, house), Δt)  # set sampling function
    switch!(house)                                     # start the thermostat
end

# first run to compile
setup()
run!(𝐶, 48)

# take measurements
println(now())
@time onthread(2) do; setup(); end
@time onthread(2) do; info = run!(𝐶, 48); end
println(info)
println("measurements:", length(house.datTr), " mean_tr=", mean(house.datTr))

t = run(@benchmarkable onthread(2) do; run!(𝐶, 48); end setup=onthread(2) do; setup(); end  evals=1 seconds=15.0 samples=100)
