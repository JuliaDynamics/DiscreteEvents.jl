#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

println("... testing multithreading  ...")

clk = Clock()
@test clk.id == 1

if VERSION ≥ v"1.3"
    if nthreads() > 1
        multiply(clk)
        @test length(clk.ac) == nthreads()-1
        for i in 2:nthreads()
            @test clk.ac[i-1].id == i
            c = pclock(clk, i)
            @test c.id == i
        end
    else
        @test_warn "no parallel threads available!" multiply(clk)
    end
else
    @test_warn "threading is available for ≥ 1.3!" multiply(clk)
end
