# Simulate.jl - development

A Julia package for **discrete event simulation**. It introduces a **clock** and allows to schedule Julia expressions and functions as **events** for later execution on the clock's time line. If we **run** the clock, the events are executed in the scheduled sequence.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://pbayer.github.io/Simulate.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://pbayer.github.io/Simulate.jl/dev)
[![Build Status](https://travis-ci.com/pbayer/Simulate.jl.svg?branch=dev)](https://travis-ci.com/pbayer/Simulate.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/pbayer/Simulate.jl?svg=true)](https://ci.appveyor.com/project/pbayer/Sim-jl)
[![codecov](https://codecov.io/gh/pbayer/Simulate.jl/branch/dev/graph/badge.svg)](https://codecov.io/gh/pbayer/Simulate.jl)
[![Coverage Status](https://coveralls.io/repos/github/pbayer/Simulate.jl/badge.svg?branch=dev)](https://coveralls.io/github/pbayer/Simulate.jl?branch=dev)

**Author:** Paul Bayer

**Development Documentation** is currently at https://pbayer.github.io/Simulate.jl/dev

## Intermediate goals for development

I want to develop `Simulate.jl` to support all major approaches to modeling and simulation:

- [x] event based,
- [x] activity based,
- [ ] state based,
- [ ] process based.

With the main two simulation hooks of `Simulate.jl`: `event!` and `SimFunction` only the first two approaches are supported.

For examples see [`docs/examples`](https://github.com/pbayer/Simulate.jl/tree/master/docs/examples) or [`docs/notebooks`](https://github.com/pbayer/Simulate.jl/tree/master/docs/notebooks).
