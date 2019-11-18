using Documenter, Simulate

makedocs(
    modules = [Simulate],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "Simulate.jl",
    authors  = "Paul Bayer",
    pages = [
        "Home" => "index.md",
        "Introduction" => "intro.md",
        "Usage" => "usage.md",
        "Modeling approaches" => "approach.md",
        hide("Examples" => "examples/examples.md",
                       ["examples/greeting.md",
                       "examples/tabletennis.md",
                       "examples/singleserver.md"]),
        "Internals" => "internals.md",
        "Troubeshooting" => "troubleshooting.md",
        "History" => "history.md"
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
