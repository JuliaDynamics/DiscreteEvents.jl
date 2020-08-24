#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#
using DiscreteEvents, DataStructures

println("... basic tests: resources  ...")

R = Resource{Int}()
@test R.items isa Deque{Int}
@test R.capacity == typemax(Int)
R = Resource{Int}(5)
@test R.capacity == 5
@test capacity(R) == 5
@test length(R) == 0
@test isempty(R)
@test !isready(R)

@test !islocked(R)
lock(R)
@test islocked(R)
unlock(R)
@test !islocked(R)
@test trylock(R)
@test islocked(R)
t = @async trylock(R)
@test !fetch(t)
unlock(R)
@test !islocked(R)

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
empty!(R)
@test isempty(R)

println("... basic tests: extended channel API  ...")
ch = Channel{Int}(5)
@test capacity(ch) == 5
@test isempty(ch)
for i in 1:5
    put!(ch, i)
end
@test length(ch) == 5
@test isfull(ch)
@test take!(ch) == 1
@test length(ch) == 4
empty!(ch)
@test isempty(ch)
