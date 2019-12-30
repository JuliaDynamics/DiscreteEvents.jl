#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
using Printf
import Dates.now
res = Dict()

btime = now()

println("... channel benchmark ...")
include("bench_channel.jl")
res["channel"] = minimum(t.times)*1e-6

println("... dice benchmark ...")
include("bench_dice.jl")
res["dice"] = minimum(t.times)*1e-6

println("... heating benchmark ...")
include("bench_heating.jl")
res["heating"] = minimum(t.times)*1e-6

println()
println("Benchmark results (minimum runtimes):")
println("=====================================")
@printf "datetime               \tchannel[ms] \tdice[ms] \theating[ms]\n"
@printf "%s\t%11.3f \t%8.3f \t%11.3f" btime res["channel"] res["dice"] res["heating"]
