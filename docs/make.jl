using Documenter, Simulate

makedocs(
    modules = [Simulate],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "Simulate.jl",
    authors  = "Paul Bayer",
    pages = [
        "Home" => "index.md",
        "Getting started" => "intro.md",
        "Building models" => "approach.md",
        "Usage" => "usage.md",
        "Examples" => ["examples/examples.md",
                       "examples/greeting.md",
                       "examples/tabletennis.md",
                       "examples/singleserver.md",
                       "examples/postoffice/postoffice.md",
                       "examples/dicegame/dicegame.md",
                       "examples/house_heating/house_heating.md"],
        "Internals" => "internals.md",
        "Parallel simulations" => "parallel.md",
        "Performance" => "performance.md",
        "Troubleshooting" => "troubleshooting.md",
        "Release notes" => "history.md"
    ]
)

deploydocs(
    repo   = "github.com/pbayer/Simulate.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
    devbranch = "master",
    devurl = "dev",
    versions = ["stable" => "v^", "v#.#", "dev" => "dev"]
)
