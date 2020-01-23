#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

println("... check if threading is available ...")
clk = Clock()

if VERSION ≥ v"1.3"
    if nthreads() > 1
        include("test_threads1.jl")
        include("test_threads2.jl")
    else
        @test_warn "no parallel threads available!" fork!(clk)
    end
else
    @test_warn "threading is available for ≥ 1.3!" fork!(clk)
end
