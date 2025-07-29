using SWIPL2J
using Documenter

DocMeta.setdocmeta!(SWIPL2J, :DocTestSetup, :(using SWIPL2J); recursive=true)

makedocs(;
    modules=[SWIPL2J],
    authors="nathanTandory <nathan.tandory@ontariotechu.net> and contributors",
    sitename="SWIPL2J.jl",
    format=Documenter.HTML(;
        canonical="https://nathanzyx.github.io/SWIPL2J.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/nathanzyx/SWIPL2J.jl",
    devbranch="master",
)
