using Documenter, PowerModelsGMD

makedocs(
    modules = [PowerModelsGMD],
    format = Documenter.HTML(analytics = "UA-367975-10", mathengine = Documenter.MathJax()),
    sitename = "PowerModelsGMD",
    authors = "Arthur Barnes, Adam Mate, and contributors.",
    pages = [
        "Home" => "index.md",
    ],
    warnonly = :missing_docs,
    checkdocs = :exports,
)

deploydocs(
    # Remote push: git@github.com:lanl-ansi/PowerModelsGMD.jl.git
    # From https://documenter.juliadocs.org/stable/lib/public/#Documenter.deploydocs
    # Do not specify any protocol - "https://" or "git@" should not be present. 
    repo = "github.com/lanl-ansi/PowerModelsGMD.jl.git",
)
