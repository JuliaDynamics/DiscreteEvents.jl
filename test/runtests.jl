using Sim
using Test

println(".... testing Sim.jl .....")
@testset "Clock.jl" begin
    include("test_Clock.jl")
end

@testset "Logger.jl" begin
        include("test_Logger.jl")
end
