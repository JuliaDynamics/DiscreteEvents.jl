# Simulate.jl

A Julia package for discrete event simulation.

`Simulate.jl` introduces a **clock** and allows to schedule Julia expressions and functions as **discrete events** for later execution on the clock's time line. Expressions or functions can register for **continuous sampling** and then are executed at each clock tick. Julia functions can also run as **processes**, which can refer to the clock, respond to events, delay etc. If we **run** the clock,  events are executed in the scheduled sequence, sampling functions are called continuously at each clock tick and processes are served accordingly.

## Installation

`Simulate.jl` is a registered package and is installed with:

```julia
pkg> add Simulate
```

The development (and sometimes not so stable version) can be installed with:

```julia
pkg> add("https://github.com/pbayer/Simulate.jl")
```

**Author:** Paul Bayer
**License:** MIT

## Changes in v0.2.0 (development)

- **next** conditional `wait!(cond)`
- conditional events with `event!(sim, ex, cond)` are executed when the conditions are met,
- `event!` can be called without the first clock argument, it then goes to `𝐶`,
- `event!` takes an expression or a SimFunction or a tuple or an array of them,
- introduced aliases: `𝐅` for `SimFunction` and `𝐏` for `SimProcess`
- introduced process-based simulation with `SimProcess` and `process!`,
- extensive documentation,
- more examples,
