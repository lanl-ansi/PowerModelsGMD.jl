using Documenter, PowerModelsGMD

makedocs(
    modules = [PowerModelsGMD],
    sitename = "PowerModelsGMD",
    authors = "Arthur Barnes, and contributors.",
    pages = [
        "Home" => "index.md",
    ]
)

deploydocs(
    repo = "github.com/lanl-ansi/PowerModelsGMD.jl.git",
)
