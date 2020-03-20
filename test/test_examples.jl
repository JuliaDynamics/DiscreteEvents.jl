println(".... run examples and notebooks ....")

using NBInclude

dir = pwd()
cd("DiscreteEvents/examples")
temp = pwd()

ex = [x for x in readdir("src") if occursin(r".jl", x)]
nb = [x for x in readdir("nb") if occursin(r".ipynb", x)]

for x in ex
    println("... include examples/src/$x:")
    include(temp*"/src/"*x)
end

for x in nb
    println("... @nbinclude examples/nb/$x:")
    @nbinclude(temp*"/nb/"*x)
end

cd(dir)
