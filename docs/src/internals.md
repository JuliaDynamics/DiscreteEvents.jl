# Internals

```@meta
CurrentModule = Sim
```

## Module
```@docs
Sim
```

`Clock` and `Logger` are implemented as state machines. The exported functions above are commands to the internal state machines.

## Types for state machines

We need some definitions for them to work.

### State machine
```@docs
SEngine
```

### States
```@docs
SState
Undefined
Idle
Empty
Busy
Halted
```

### Events
```@docs
SEvent
Init
Setup
Switch
Log
Step
Run
Start
Stop
Resume
Clear
```

## Transition functions

In state machines transitions occur depending of the states and events. This is done through the `step!` functions.
```@docs
step!
```

## Other internal types and functions
```@docs
SimEvent
Sample
nextevent
nextevtime
```
