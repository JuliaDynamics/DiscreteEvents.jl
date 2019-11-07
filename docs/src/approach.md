### Approaches to modeling and simulation

I want to develop `Simulate.jl` to support four major approaches to modeling and simulation of discrete event systems (DES):

1. **event based**: events occur in time and trigger actions, which may
cause further events …
2. **activity based**: activities occur in time and cause other activities …
3. **state based**: events occur in time and trigger actions of entities (e.g. state machines) depending on their current state, those actions may cause further events …
4. **process based**: entities in a DES are modeled as processes waiting for
events and then acting according to the event and their current state …

Choi and Kang have written an entire book about the first three approaches [1]. Cassandras and Lafortune in *Introduction to Discrete Event Systems* call the first three approaches "the event scheduling scheme" and the 4th one "the process-oriented simulation scheme". Whoever is right, there are communities and their views behind those approaches and I want `Simulate.jl` to be useful for them all.

- [1] Choi and Kang: *Modeling and Simulation of Discrete-Event Systems*, Wiley, 2013
- [2] Cassandras and Lafortune: *Introduction to Discrete Event Systems*, Springer, 2008, Ch. 10
