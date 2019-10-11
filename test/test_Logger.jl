a = 0
b = 0
c = 0

sim = Clock()
L = Logger()

init!(L, sim)
setup!(L, [:a, :b, :c])
record!(L)
@test L.last["a"] == a
@test L.last["b"] == b
@test L.last["c"] == c

switch!(L, 1)
record!(L)

switch!(L, 2)
for i in 1:10
    global a = i
    global b = i^2
    global c = factorial(i)
    record!(L)
end
