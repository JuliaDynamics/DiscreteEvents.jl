# Processes

Processes are typical event sequences implemented in a function. They
run as asynchronous tasks and get registered to a clock.

```@docs
Prc
process!
interrupt!
```

## Delay and wait …

In order to implement a process (an event sequence) functions can call `delay!` or `wait!` on the clock or `take!` and `put!` on  channels. They are then suspended until a given time or until certain conditions are met or requested resources are available.

```@docs
delay!
wait!
```

!!! warning "Processes use blocking calls and are not responsive!"

    If the typical event sequence of a process is interrupted by other events (e.g. a customer reneging, a failure) the process is blocked and has to use exception handling to tackle it.

## Now

Processes (or asynchronous tasks in general) transfer IO-operations with a `now!` call to the (master) clock so that they get executed at the current clock time. As a convenience you can print directly to the clock.

```@docs
now!
print(::Clock, ::Any)
println(::Clock, ::Any)
```
