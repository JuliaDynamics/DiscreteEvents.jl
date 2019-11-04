using Sim, Unitful, Test
import Unitful: Time, ms, s, minute, hr

println(".... testing Sim.jl .....")
@testset "Clock.jl" begin
    include("test_Clock.jl")
end

@testset "Logger.jl" begin
        include("test_Logger.jl")
end
