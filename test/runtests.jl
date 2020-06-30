#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

using DiscreteEvents, Random, Unitful, Test, .Threads, DataStructures
import Unitful: Time, ms, s, minute, hr

x = 2 # set global (Main) variable for mocking fclosure.jl doctest line 90

println(".... testing DiscreteEvents.jl .....")
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

@testset "timer.jl" begin
    include("test_timer.jl")
end

@testset "resources.jl" begin
    include("test_resources.jl")
end

# if (VERSION ≥ v"1.3") && (nthreads() > 1)
#     @testset "doctests" begin
#         include("test_docs.jl")
#     end
# else
#     println("... no doctests with Julia $VERSION, nthreads: $(nthreads()) ...")
# end
#
# @testset "examples" begin
#     include("test_examples.jl")
# end

println(".... finished testing DiscreteEvents.jl ....")
