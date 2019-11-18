# Internals

```@meta
CurrentModule = Simulate
```

## Module
```@docs
Simulate
```

The module contains two main types: `Clock` and `Logger`. Both are implemented as state machines. The implementation functions and types are not exported. The exported functions documented above under **Usage** are commands to the internal state machines.

## State machines

We have some definitions for them to work.

```@docs
SEngine
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
Start
Stop
Resume
Clear
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
simExec
nextevent
nextevtime
checktime
setTimes
startup!
loop
scale
```
