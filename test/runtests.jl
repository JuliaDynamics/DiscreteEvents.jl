using Sim
using Test

@testset "Sim.jl" begin
    println("... testing Clock.jl ...")
    include("test_Clock.jl")
    println("... testing Logger.jl ...")
    include("test_Logger.jl")
end
