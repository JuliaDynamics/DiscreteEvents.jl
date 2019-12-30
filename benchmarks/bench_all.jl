#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
using Printf, Statistics
import Dates.now
res = Dict()
resm = Dict()

btime = now()

println("... channel benchmark ...")
include("bench_channel.jl")
res["channel"] = minimum(t.times)*1e-6
resm["channel"] = mean(t.times)*1e-6

println("... dice benchmark ...")
include("bench_dice.jl")
res["dice"] = minimum(t.times)*1e-6
resm["dice"] = mean(t.times)*1e-6

println("... heating benchmark ...")
include("bench_heating.jl")
res["heating"] = minimum(t.times)*1e-6
resm["heating"] = mean(t.times)*1e-6

println()
println("Benchmark results:")
println("==================")
@printf "time    \tdatetime               \tchannel [ms] \tdice [ms] \theating [ms]\n"
@printf "minimum \t%s\t%12.3f \t%9.3f \t%12.3f\n" btime res["channel"] res["dice"] res["heating"]
@printf "mean    \t%s\t%12.3f \t%9.3f \t%12.3f\n" btime resm["channel"] resm["dice"] resm["heating"]
