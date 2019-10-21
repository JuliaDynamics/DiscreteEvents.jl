# Sim.jl

A Julia package for discrete event simulation.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://pbayer.github.io/Sim.jl/stable)
[![Build Status](https://travis-ci.com/pbayer/Sim.jl.svg?branch=master)](https://travis-ci.com/pbayer/Sim.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/pbayer/Sim.jl?svg=true)](https://ci.appveyor.com/project/pbayer/Sim-jl)
[![Codecov](https://codecov.io/gh/pbayer/Sim.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/Sim.jl)
[![Coverage Status](https://coveralls.io/repos/github/pbayer/Sim.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/Sim.jl?branch=master)

**Author:** Paul Bayer

## A silly example

```julia
julia> using Sim

julia> sim = Clock();

julia> comm = ["Hi, nice to meet you!", "How are you?", "Have a nice day!"];

julia> greet(name, n) =  @printf("%5.2f s, %s: %s\n", now(sim), name, comm[n])
greet (generic function with 1 method)

julia> function foo(n)
           greet("Foo", n)
           event!(sim, :(bar($n)), after, 2*rand())
       end
foo (generic function with 1 method)

julia> function bar(n)
           greet("Bar", n)
           if n < 3
               event!(sim, :(foo($n+1)), after, 2*rand())
           else
               println("bye bye")
           end
         end
bar (generic function with 1 method)

julia> event!(sim, :(foo(1)), at, 10*rand());

julia> run!(sim, 20)
 7.18 s, Foo: Hi nice to meet you!
 7.92 s, Bar: Hi nice to meet you!
 9.54 s, Foo: How are you?
10.68 s, Bar: How are you?
11.96 s, Foo: Have a nice day!
12.69 s, Bar: Have a nice day!
bye bye
Finished: 6 events, simulation time: 20.0
```

For further examples see `docs/examples` or `docs/notebooks`.
