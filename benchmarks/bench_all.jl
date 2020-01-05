#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
using Printf, Statistics, Simulate, BenchmarkTools
import Dates.now

struct RES
    min::Float64
    mean::Float64
    nevents::Int64
    nsample::Int64
    nactions::Int64
    minact::Float64
    meanact::Float64
end
Base.Array(r::RES) = [r.min, r.mean, r.nevents, r.nsample, r.nactions, r.minact, r.meanact]
function benchresult(trial::BenchmarkTools.Trial, clk::Clock)
    _min = minimum(t.times)*1e-6
    _mean = mean(t.times)*1e-6
    nevents = clk.evcount
    nsample = clk.scount
    nactions = clk.evcount+clk.scount
    minact = _min/nactions*1e3
    meanact = _mean/nactions*1e3
    return RES(_min,_mean,nevents,nsample,nactions,minact,meanact)
end
res = Dict()

btime = now()

println("... channel benchmark ...")
include("bench_channel.jl")
res["channel"] = benchresult(t, 𝐶)

println("... dice benchmark ...")
include("bench_dice.jl")
res["dice"] = benchresult(t, clk)

println("... heating benchmark ...")
include("bench_heating.jl")
res["heating"]  = benchresult(t, 𝐶)

arr = sum(hcat(Array(res["channel"]), Array(res["dice"]), Array(res["heating"])), dims=2)
arr[6] = arr[1]/arr[5]*1e3
arr[7] = arr[2]/arr[5]*1e3
res["sum"] = RES(arr...)

println()
println("Benchmark results:")
println("==================")
@printf "time    \tdatetime               \tchannel [ms] \tdice [ms] \theating [ms] \t    sum [ms]\n"
@printf "minimum \t%s\t%12.3f \t%9.3f \t%12.3f \t%12.3f\n" btime res["channel"].min res["dice"].min res["heating"].min res["sum"].min
@printf "mean    \t%s\t%12.3f \t%9.3f \t%12.3f \t%12.3f\n" btime res["channel"].mean res["dice"].mean res["heating"].mean res["sum"].mean
println()
println("action times:")
println("-------------")
@printf "time    \tdatetime               \tchannel [μs] \tdice [μs] \theating [μs] \toverall [μs]\n"
@printf "minimum \t%s\t%12.3f \t%9.3f \t%12.3f \t%12.3f\n" btime res["channel"].minact res["dice"].minact res["heating"].minact res["sum"].minact
@printf "mean    \t%s\t%12.3f \t%9.3f \t%12.3f \t%12.3f\n" btime res["channel"].meanact res["dice"].meanact res["heating"].meanact res["sum"].meanact
