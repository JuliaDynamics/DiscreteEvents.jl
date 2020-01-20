#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

println("... testing multithreading  ...")

clk = Clock()
@test clk.id == 1

if VERSION ≥ v"1.3"
    if nthreads() > 1
        println("... multiply! ...")
        multiply!(clk)
        @test length(clk.ac) ≥ (nthreads() >>> 1)
        # for i in 2:nthreads()
        #     @test clk.ac[i-1].id == i
        #     c = pclock(clk, i)
        #     @test c.id == i
        # end
        t1 = clk.ac[1].id        # get id of first parallel clock

        println("... remote error handling ...")
        @test talk(clk, t1, Simulate.Clear()).x isa ErrorException
        st = talk(clk, t1, Simulate.Diag()).x[1]
        @test occursin(r"^activeClock\(\:\:Channel\{Any\}\) at threads\.jl", string(st))

        println("... register parallel events, cevents, samples ...")
        a = 0
        ev = Simulate.SimEvent(SF(()->global a+=1),Main,1.0,0.0)
        @test talk(clk, t1, Simulate.Register(ev)).x == 1.0
        c2 = pclock(clk, t1)
        @test length(c2.sc.events) == 1
        cev = Simulate.SimCond(SF(≥, SF(tau, c2), 5), SF(()->global a+=1), Main)
        @test talk(clk, t1, Simulate.Register(cev)).x == 0.0
        @test length(c2.sc.cevents) == 1
        b = 0
        sp = Simulate.Sample(SF(()->global b+=1), Main)
        @test talk(clk, t1, Simulate.Register(sp)).x == true
        @test length(c2.sc.sexpr) == 1

        println("... run parallel clock 1 (thread $t1) ...")
        @test talk(clk, t1, Simulate.Run(10.0)).x == 10.0
        @test c2.time ≈ 10
        @test c2.scount == 1000
        @test a == 2
        @test b == 1000

        println("... stop parallel clocks ...")
        foreach(x->put!(x.ch, Simulate.Stop()), clk.ac)
        @test all(x->istaskdone(x.ref[]), clk.ac)
        @test all(x->x.ch.state == :closed, clk.ac)
    else
        @test_warn "no parallel threads available!" multiply!(clk)
    end
else
    @test_warn "threading is available for ≥ 1.3!" multiply!(clk)
end
