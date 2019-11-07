using Simulate, Unitful, Test
import Unitful: Time, ms, s, minute, hr

println(".... testing Simulate.jl .....")
@testset "clock.jl" begin
    include("test_clock.jl")
end

@testset "process.jl" begin
    include("test_process.jl")
end

@testset "logger.jl" begin
        include("test_logger.jl")
end
