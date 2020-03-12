#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

println("... basic tests: printing  ...")

R = Resource{Int}()
@test R.items isa Deque{Int}
@test R.capacity == typemax(Int)
R = Resource{Int}(5)
@test R.capacity == 5
@test capacity(R) == 5
@test length(R) == 0
@test isempty(R)
@test !isready(R)
for i in 1:5
    push!(R, i)
end
@test isready(R)
@test !isempty(R)
@test isfull(R)
@test length(R) == 5
@test_throws ArgumentError push!(R, 6)
@test_throws ArgumentError pushfirst!(R, 0)
@test first(R) == 1
@test last(R) == 5
@test pop!(R) == 5
@test popfirst!(R) == 1
@test first(R) == 2
pushfirst!(R, 1)
@test first(R) == 1
