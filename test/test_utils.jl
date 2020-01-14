#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

println("... basic tests: utils ...")
a = 1
reset!(𝐶)
@test !tau(>=, 1)
@test tau(<, 1)
@test_throws AssertionError tau(<<, 1)
@test tau(<=, :a)

b = 2
@test val(1, <=, 2)
@test_throws AssertionError val(1, <<, 1)
@test val(1, <, :b)
@test val(:a, <=, 2)
@test val(:a, <, :b)
@test !val(:a, >, :b)

@test (@SF :sin pi) == SF(sin, pi)
incra() = global a += 1
event!((@SF incra), after, 3)
@test a == 1
run!(𝐶, 5)
@test a == 2
event!((@SF incra), (@tau :>= 8))
run!(𝐶, 5)
@test a == 3
event!((@SF incra), after, 3)
event!(((@SF incra), (@SF incra)), ((@tau :>= 12), (@val :a :>= 4)))
run!(𝐶, 5)
@test a == 6

sp = @SP 1 :sin pi
@test sp.id == 1
@test sp.func == sin
@test sp.arg[1] == pi

c = Clock()
run!(c, 5)
@test (@tau c) == 5
@test (@tau) == 15

@test Simulate.evExec(@tau c :(==) 5)   # :(==) is strange, but :== does not work
@test !Simulate.evExec(@tau :≥ 100)
@test Simulate.evExec(@tau :< 100)
@test Simulate.evExec(@tau :> :a)
event!(SF(()->global a+=1), (@tau :>= 18))
run!(𝐶, 5)
@test a == 7

@test Simulate.evExec(@val 1 :≤ 2)
@test Simulate.evExec(@val :a :≤ 7)
event!(SF(()->global a+=1), ((@tau :>= 23), (@val :a :<= 8)))
run!(𝐶, 5)
@test a == 8
