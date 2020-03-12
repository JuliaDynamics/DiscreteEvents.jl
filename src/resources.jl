#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

abstract type AbstractResource end

"""
    Resource{T}(capacity)

A Resource implements a [`Deque`](https://juliacollections.github.io/DataStructures.jl/latest/deque/)
but with a limited capacity. To

- `capacity::Int=typemax(Int)`: the capacity is limited to the given integer.

# Example
```jldoctest
julia> 
```
"""
mutable struct Resource{T} <: AbstractResource
    items::Deque{T}
    capacity::Int

    Resource{T}(capacity::Int=typemax(Int)) where T = new{T}(Deque{T}(), capacity)
end

"Get the capacity of a resource"
DataStructures.capacity(r::Resource) = r.capacity

"Test whether the resource is full"
DataStructures.isfull(r::Resource) = length(r) ≥ capacity(r)

"Test whether an item is available"
Base.isready(r::Resource) = !isempty(r.items)

"Test whether the resource is empty"
Base.isempty(r::Resource) = isempty(r.items)

"Get the number of elements available"
Base.length(r::Resource) = length(r.items)

"Add an element to the back of a resource deque"
Base.push!(r::Resource, x) =
    !isfull(r) ? push!(r.items, x) : throw(ArgumentError("Resource must be non-full"))

"Remove an element from the back of a resource deque"
Base.pop!(r::Resource) = pop!(r.items)

"Add an element to the front of a resource deque"
Base.pushfirst!(r::Resource, x) =
    !isfull(r) ? pushfirst!(r.items, x) : throw(ArgumentError("Resource must be non-full"))

"Remove an element from the front of a resource deque"
Base.popfirst!(r::Resource) = popfirst!(r.items)

"Get the element at the front of a resource deque"
Base.first(r::Resource) = first(r.items)

"Get the element at the back of a resource deque"
Base.last(r::Resource) = last(r.items)
