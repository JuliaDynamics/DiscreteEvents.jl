# Simulate.jl - development

A Julia package for **discrete event simulation**. It introduces a **clock** and allows to schedule Julia expressions and functions as **events** for later execution on the clock's time line. If we **run** the clock, the events are executed in the scheduled sequence.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://pbayer.github.io/Simulate.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://pbayer.github.io/Simulate.jl/dev)
[![Build Status](https://travis-ci.com/pbayer/Simulate.jl.svg?branch=dev)](https://travis-ci.com/pbayer/Simulate.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/p5trstrte9il7rm1/branch/dev?svg=true)](https://ci.appveyor.com/project/pbayer/simulate-jl-ueug1/branch/dev)
[![codecov](https://codecov.io/gh/pbayer/Simulate.jl/branch/dev/graph/badge.svg)](https://codecov.io/gh/pbayer/Simulate.jl)
[![Coverage Status](https://coveralls.io/repos/github/pbayer/Simulate.jl/badge.svg?branch=dev)](https://coveralls.io/github/pbayer/Simulate.jl?branch=dev)

**Author:** Paul Bayer

**Development Documentation** is currently at https://pbayer.github.io/Simulate.jl/dev

## Intermediate goals for development

I want to develop `Simulate.jl` to support four major approaches to modeling and simulation of discrete event systems (DES):

- [x] **event based**: events occur in time and trigger actions, which may
cause further events …
- [x] **activity based**: activities occur in time and cause other activities …
- [x] **state based**: events occur in time and trigger actions of entities (e.g. state machines) depending on their current state, those actions may cause further events …
- [ ] **process based**: entities in a DES are modeled as processes waiting for
events and then acting according to the event and their current state …

With the current main two simulation hooks of `Simulate.jl`: `event!` and `SimFunction` the first three approaches are supported. Therefore the next step will be to integrate a process based modeling and simulation approach. Then all four approaches can be combined.

For examples see [`docs/examples`](https://github.com/pbayer/Simulate.jl/tree/master/docs/examples) or [`docs/notebooks`](https://github.com/pbayer/Simulate.jl/tree/master/docs/notebooks).
