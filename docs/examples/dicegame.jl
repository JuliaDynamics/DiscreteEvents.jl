using Simulate, Distributions

function boy(sim::Simulation, simlog, nr::Int64, bowls)
  roll = logvar("Boy"*string(nr), 0)
  logvar2log(simlog, roll)
  while true
    yield(Timeout(sim, 1))
    mystock = bowls[nr]
    roll.value = rand(DiscreteUniform(1, 6))
    matches = min(roll.value, mystock)
    bowls[nr]   -= matches
    bowls[nr+1] += matches
  end
end

# initalization
srand(1234)       # seed random number generator for reproducibility
simlog = newlog()
bowls = Dict(1=>999, 2=>0, 3=>0, 4=>0, 5=>0, 6=>0) # initialize bowls with matches
dict2log(simlog, bowls, redict=Dict(1=>"Bowl1",2=>"Bowl2",3=>"Bowl3",
                                    4=>"Bowl4",5=>"Bowl5",6=>"Output"))
sim = Simulation()
for i = 1:5
  @process boy(sim, simlog, i, bowls)  # create 5 players
end
@process logtick(sim, simlog, 1)         # add logging after each run
run(sim, 101)
d = log2df(simlog);
tail(d)
