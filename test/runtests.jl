#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

using Simulate, Random, Unitful, Test, .Threads
import Unitful: Time, ms, s, minute, hr

println(".... testing Simulate.jl .....")
@testset "clock.jl" begin
    include("test_clock.jl")
end

@testset "threads.jl" begin
    include("test_threads.jl")
end

@testset "channel 1 example" begin
    include("test_channels1.jl")
end

@testset "process.jl" begin
    include("test_process.jl")
end
