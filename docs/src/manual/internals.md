# Internals

```@meta
CurrentModule = Simulate
```

## Clocks

```@docs
AbstractClock
```

`Simulate.jl` contains several clock types: [`Clock`](@ref), [`ActiveClock`](@ref) and [`RTClock`](@ref). They are implemented as state machines. Their implementation are internal and not exported.

### Clock states

Defined clock states.

```@docs
ClockState
Undefined
Idle
Empty
Busy
Halted
```

### Clock events

Defined clock events.

```@docs
ClockEvent
Init
Setup
Step
Run
Reset
Query
Diag
Response
Register
Forward
Done
Sync
Start
Stop
Resume
Clear
```

### Multithreading

Internal functions used for multithreading.

```@docs
start_threads
activeClock
spawnid
```

### Transition functions

The internal clock transition function has several methods for different combinations of clock types, states and events:

```@docs
step!
```

## Assigning and registering events.
```@docs
assign
register
register!
```

## Other internal types and functions
```@docs
nextevent
nextevtime
evaluate
evExec
sfExec
setTimes
do_event!
do_tick!
do_step!
do_run!
startup!
wakeup
init!
loop
scale
```
