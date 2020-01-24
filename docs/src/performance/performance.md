# Performance

For larger models and simulations over longer timeframes performance matters and
users can do a lot to get more of it. The generic process of getting more performant simulations is:

1. Follow the [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-tips-1) in the Julia manual,
2. follow the hints in this chapter,
3. parallelize simulations following.  

## Functions vs quoted expressions

- for events use `SimFunction` instead of quoted expressions. It is much faster.

- benchmarks

## Use of variables

- if values don't change, declare them as `const`,
- declare composite global variables, achieve type stability

- benchmarks

## Event based simulations are faster than process based ones

If you work on a single thread, sequential execution of events is faster than
events + task switching. The convenience of process based models comes at a
performance cost.

- benchmark results

## Reactive programming

You can speedup process based simulations quite a bit if you design your processes
as state machines running in run-to-completion ([RTC](https://www.sciencedirect.com/topics/computer-science/run-to-completion)) loops without blocking calls. Instead
of `delay!` or `wait!` they schedule
events for themselves with the clock.

- example
- benchmark results
