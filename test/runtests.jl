#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#
using DiscreteEvents, Test, SafeTestsets, .Threads

# test_basics.jl has to be evaluated in global scope
@testset     "Basics"       begin include("test_basics.jl") end

@safetestset "Events"       begin include("test_events.jl") end
@safetestset "Clock"        begin include("test_clock.jl")  end
@safetestset "Units"        begin include("test_units.jl")  end
# @safetestset "Threads"      begin include("test_threads.jl") end
@safetestset "Channel 1"    begin include("test_channels1.jl") end
@safetestset "Processes"    begin include("test_process.jl") end
@safetestset "Resources"    begin include("test_resources.jl") end
@safetestset "Utilities"    begin include("test_utils.jl") end
@safetestset "Macros"       begin include("test_macros.jl") end

if (VERSION ≥ v"1.3") && (nthreads() > 1)
    @safetestset "timer.jl" begin include("test_timer.jl") end
else
    println("... timer requires Julia ≥ 1.3, nthreads() > 1")
end

@safetestset "examples"     begin include("test_examples.jl") end

if VERSION ≥ v"1.8"
    @safetestset "Aqua"     begin include("test_aqua.jl") end
end

println(".... finished testing DiscreteEvents.jl ....")
