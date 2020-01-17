# Internals

```@meta
CurrentModule = Simulate
```

## State machines

`Simulate.jl` contains two clock types: [`Clock`](@ref) and [`ActiveClock`](@ref). Both are implemented as state machines. The implementation functions and types are not exported. The exported functions documented above under **Usage** are commands to the internal state machines.

We have some definitions for them to work.

```@docs
StateMachine
```

### States

Defined states for state machines.

```@docs
SState
Undefined
Idle
Empty
Busy
Halted
```

### Events

Defined events.

```@docs
SEvent
Init
Setup
Switch
Log
Step
Run
Reset
Query
Response
Register
Sync
Start
Stop
Resume
Clear
```

### Multithreading

```@docs
start_threads
startup
activeClock
```

### Transition functions

In state machines transitions occur depending on states and events. The different transitions are described through different methods of the `step!`-function.
```@docs
step!
```

## Other internal types and functions
```@docs
SimEvent
SimCond
Sample
sconvert
nextevent
nextevtime
checktime
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
