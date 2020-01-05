using Simulate, Random, Unitful, Test
import Unitful: Time, ms, s, minute, hr

println(".... testing Simulate.jl .....")
@testset "clock.jl" begin
    include("test_clock.jl")
end

@testset "channel 1 example" begin
    include("test_channels1.jl")
end

@testset "process.jl" begin
    include("test_process.jl")
end

@testset "utils.jl" begin
    include("test_utils.jl")
end
