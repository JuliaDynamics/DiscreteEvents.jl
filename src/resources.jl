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
with a limited capacity. If used in multithreading applications, the user must avoid race
conditions by explicitly wrapping modifying calls with `lock-unlock`.

# Fields
- `items::Deque{T}`: resource buffer
- `capacity::Number=Inf`: the capacity is limited to the given integer,
- `lock::ReentrantLock`: a lock for coordinating resource access by tasks.

# Example
```jldoctest
julia> 
```
!!! note
    In order to use the full interface to `Resource` you have to load `DataStructures`.
"""
mutable struct Resource{T} <: AbstractResource
    items::Deque{T}
    capacity::Int
    lock::ReentrantLock

    function Resource{T}(capacity::U=Inf) where {T,U<:Number}
        if isinf(capacity)
            new{T}(Deque{T}(), typemax(Int), ReentrantLock())
        else
            new{T}(Deque{T}(), capacity, ReentrantLock())
        end
    end
end

"""
    capacity(r::Resource)

Get the capacity of a resource
"""
DataStructures.capacity(r::Resource) = r.capacity

"""
    isfull(r::Resource)

Test whether the resource is full
"""
DataStructures.isfull(r::Resource) = length(r) ≥ capacity(r)

"""
    isready(r::Resource)

Test whether an item is available.
"""
Base.isready(r::Resource) = !isempty(r.items)

"""
    isempty(r::Resource)

Test whether the resource is empty.
"""
Base.isempty(r::Resource) = isempty(r.items)

"""
    empty!(r::Resource)

Reset the resource buffer (deque).
"""
Base.empty!(r::Resource) = empty!(r.items)

"""
    length(r::Resource)

Get the number of elements available.
"""
Base.length(r::Resource) = length(r.items)

"""
    push!(r::Resource, x)

Add an element to the back of a resource deque.
"""
Base.push!(r::Resource, x) =
    !isfull(r) ? push!(r.items, x) : throw(ArgumentError("Resource must be non-full"))

"""
    pop!(r::Resource)

Remove an element from the back of a resource deque.
"""
Base.pop!(r::Resource) = pop!(r.items)

"""
    pushfirst!(r::Resource, x)

Add an element to the front of a resource deque.
"""
Base.pushfirst!(r::Resource, x) =
    !isfull(r) ? pushfirst!(r.items, x) : throw(ArgumentError("Resource must be non-full"))

"""
    popfirst!(r::Resource)

Remove an element from the front of a resource deque.
"""
Base.popfirst!(r::Resource) = popfirst!(r.items)

"""
    first(r::Resource)

Get the element at the front of a resource deque.
"""
Base.first(r::Resource) = first(r.items)

"""
    last(r::Resource)

Get the element at the back of a resource deque.
"""
Base.last(r::Resource) = last(r.items)

"""
    lock(r::Resource)

Acquire the resource lock when it becomes available. If the lock is already locked by a
different task/thread, wait for it to become available.

Each lock must be matched by an unlock.
"""
Base.lock(r::Resource) = lock(r.lock)

"""
    unlock(r::Resource)

Releases ownership of the resource lock.

If this is a recursive lock which has been acquired before, decrement an internal counter
and return immediately.
"""
Base.unlock(r::Resource) = unlock(r.lock)

"""
    islocked(r::Resource)

Check whether the lock is held by any task/thread. This should not be used for
synchronization (see instead trylock).
"""
Base.islocked(r::Resource) = islocked(r.lock)

"""
    trylock(r::Resource)

Acquire the resource lock if it is available, and return true if successful. If the lock
is already locked by a different task/thread, return false.

Each successful trylock must be matched by an unlock.
"""
Base.trylock(r::Resource) = trylock(r.lock)

# -----------------------------------------------------
# extended interface to Julia channels
# -----------------------------------------------------

"""
    capacity(ch::Channel)

Get the capacity of a channel.
"""
DataStructures.capacity(ch::Channel) = ch.sz_max

"""
    isfull(ch::Channel)

Test whether a channel is full.
"""
DataStructures.isfull(ch::Channel) = length(ch) ≥ capacity(ch)

"""
length(ch::Channel)

Get the number of items in a channel.
"""
Base.length(ch::Channel) = length(ch.data)


if VERSION < v"1.5"
    """
     isempty(ch::Channel)

    Test whether a channel is empty.
    """
    Base.isempty(ch::Channel) = isempty(ch.data)
end

"""
    empty!(ch::Channel)

Reset a channel, throw away the elements stored to it.
"""
Base.empty!(ch::Channel) = foreach((x)->take!(ch), 1:length(ch))
