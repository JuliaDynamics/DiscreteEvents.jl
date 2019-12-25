# Performance

Julia is fast and most modern computers running it are fast too. Therefore for
small models and simulations users probably won't care much about performance and
will still get quick results. But for larger models and simulations over longer
timeframes performance matters and users can do a lot to get more of it.

## Functions vs quoted expressions

- use functions with `SimFunction` instead of quoted expressions

benchmarks

## Use of variables

- declare composite global variables, achieve type stability

benchmarks

## Reactive programming

- avoid blocking arguments like `delay!` and `wait!` entirely

benchmarks

## Parallelizing simulations

- how to do simulations in parallel
- simulations on multiple threads (v0.3)

benchmarks

## Benchmarks

- comparisons with other DES frameworks
