using Documenter, PowerModelsGMD

makedocs(
    modules = [PowerModelsGMD],
    format = Documenter.HTML(analytics = "UA-367975-10", mathengine = Documenter.MathJax()),
    sitename = "PowerModelsGMD",
    authors = "Arthur Barnes, Adam Mate, and contributors.",
    pages = [
        "Home" => "index.md",
    ]
)

deploydocs(
    repo = "github.com/lanl-ansi/PowerModelsGMD.jl.git",
)
