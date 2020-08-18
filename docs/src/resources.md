# Resources

Shared resources with limited capacity are often needed in simulations.

1. One approach to model them, is to use Julia [`Channel`](https://docs.julialang.org/en/v1/base/parallel/#Base.Channel)s with their API. This is thread-safe and thus should be preferred for multithreading applications.
2. Using `Resource` is a second possibility to model shared resources. Its interface gives more flexibility and is faster in single threaded applications, but in multithreading the user must avoid race conditions by explicitly wrapping access with `lock -… access …- unlock` – if the resources are shared by multiple tasks.

```@docs
Resource
capacity
isfull
isready
isempty
empty!
length
push!
pop!
pushfirst!
popfirst!
first
last
```

`Resource` provides a `lock-unlock` API for multithreading applications.

```@docs
lock
unlock
islocked
trylock
```
