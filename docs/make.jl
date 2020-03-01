using Documenter, DiscreteEvents

makedocs(
    modules = [DiscreteEvents],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "DiscreteEvents.jl",
    authors  = "Paul Bayer",
    pages = [
        "Home" => "index.md",
        "News" => "news.md",
        "Manual" => [
            "intro.md",
            "usage.md",
            "troubleshooting.md",
            "history.md"]
    ]
)

deploydocs(
    repo   = "github.com/pbayer/DiscreteEvents.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
    devbranch = "master",
    devurl = "dev",
    versions = ["stable" => "v^", "v#.#", "dev" => "dev"]
)
