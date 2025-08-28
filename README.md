# SWIPL2J
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://nathanlloyd7.github.io/SWIPL2J.jl/dev/)

A Julia package to bridge [SWI-Prolog](https://www.swi-prolog.org/) with Julia.

## Motivation
We were looking to develop logical agents through the Agents.jl package and had looked into existing packages to do the job, namely:
* [Julog](https://github.com/ztangent/Julog.jl) 
* [Herb-SWIPL](https://github.com/Herb-AI/HerbSWIPL.jl)

With these packages we were unable to run our agent-based simulations due to the requirement of nested infix operators and comparison operators, which is a known limitation of Julog, upon which Herb-SWIPL is also built.

Our solution here is to pass information through the command line, from Julia to SWIPL via [Julia.Base I/O and Network](https://docs.julialang.org/en/v1/base/io-network/). This simply utilizes the `open(command)` functionality, which enables a command to run asynchronously, and return a `process::IO` object. We then make use of generic I/O functionalities, `read`, `write` and `flush`. This is a relatively simple workaround, thus, this package aims only to provide basic helpful functions to get you on your way, a selection of tests, and documentation to get you started should you wish to interface Julia and SWI-Prolog.

As each  `process::IO` object runs asynchronously and can be assigned to some variable, in our work with [Agents.jl](https://juliadynamics.github.io/Agents.jl/stable/), each agent is instantiated with a `process::IO` object for its knowledge-base.

## Documentation
Please see our documentation [here](https://nathanlloyd7.github.io/SWIPL2J.jl/dev/).

## Performance
This section will come later. 
* We plan to compare to Herb-SWIPL and Julog.
* We plan to demonstrate Agents.jl with SWIPL2J and compare against other agent packages with logical agent capabilities or interfaces.

