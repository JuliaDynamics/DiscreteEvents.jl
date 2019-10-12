a = 0
b = 0
c = 0

sim = Clock()
L = Logger()

init!(L, sim)
setup!(L, [:a, :b, :c])
record!(L)
@test L.last[2] == ("a", a)
@test L.last[3] == ("b", b)
@test L.last[4] == ("c", c)

switch!(L, 1)
record!(L)

switch!(L, 2)
for i in 1:10
    global a = i
    global b = i^2
    global c = factorial(i)
    record!(L)
end
@test sum(L.df.a) == sum(1:10)
@test sum(L.df.b) == sum((1:10).^2)
@test sum(L.df.c) == sum(factorial.(1:10))

clear!(L)
@test length(L.last) == 0
@test size(L.df, 1) == 0
for i in 11:15
    global c = factorial(i)
    record!(L)
end
@test size(L.df,1) == 5
@test L.df.c[end] == factorial(15)
