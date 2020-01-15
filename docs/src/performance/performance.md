# Performance

Julia is fast and most modern computers running it are fast too. Therefore for
small models and simulations users probably won't care much about performance and
will still get quick results. But for larger models and simulations over longer
timeframes performance matters and users can do a lot to get more of it.

## Functions vs quoted expressions

- use functions with `SimFunction` instead of quoted expressions

benchmarks

## Use of variables

- if values don't change, declare them as `const`,
- declare composite global variables, achieve type stability

benchmarks

## Event based simulations are faster than process based ones

If you work on a single thread, sequential execution of events is faster than
events + task switching. The convenience of process based models comes at a
performance cost.

benchmark results
