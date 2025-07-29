using SWIPL2J
using Documenter

DocMeta.setdocmeta!(SWIPL2J, :DocTestSetup, :(using SWIPL2J); recursive=true)

makedocs(;
    modules=[SWIPL2J],
    authors = "Nathan Lloyd <nathan.lloyd@ontariotechu.net>, 
               Nathan Tandory <nathan.tandory@ontariotechu.net>,
               Peter R. Lewis <peter.lewis@ontariotechu.ca>",
    sitename="SWIPL2J.jl",
    format=Documenter.HTML(;
        canonical="https://nathanlloyd7.github.io/SWIPL2J.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Reference" => "reference.md",
        "Examples" => "examples.md",
        "Install" => "install.md",
    ],
)

deploydocs(;
    repo="github.com/Nathanlloyd7/SWIPL2J.jl",
    devbranch="main",
)
