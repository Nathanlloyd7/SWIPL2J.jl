```@meta
CurrentModule = SWIPL2J
```

# SWIPL2J Examples
On this page we demonstrate simple examples and use cases.

## Basic stream, consulting, and querying example

```julia
filename::String = "example.pl"

open(filename, "w")     # Create a file for the example

swipl::IO = SWIPL2J.start_swipl()   # Open an SWI-Prolog process

# Create a new stream for the SWI-Prolog process into the file
stream::PrologStream = SWIPL2J.open_stream(swipl, filename, :write, false, "stream_alias")

# Write some facts into the file
SWIPL2J.write(stream, "fruit(apple).\n")
SWIPL2J.write(stream, "fruit(orange).\n")

SWIPL2J.close(stream)   # Close the stream

SWIPL2J.consult_file(swipl, filename)   # Begin consulting the file

# Query an expected boolean value from the SWI-Prolog process
result1::Bool = query_bool(swipl, "fruit(apple)")
println("Result of `fruit(apple)`: $(result1)")

# As we are not making any more queries to this file, unload it
SWIPL2J.unload_file(swipl, filename)    # Unload the file since we no longer need it

SWIPL2J.close(swipl)    # Close the SWI-Prolog process
```

## Querying

*SWIPL2J* has 4 querying functions, `query_bool`, `query_value`, and 
`query_all_values`, and `query_manual`

```julia
filename::String = "example.pl"
open(filename, "w")     # Create a file for the example
swipl::IO = SWIPL2J.start_swipl(filename)

# -----------query_bool------------
boolean::Bool = SWIPL2J.query_bool(swipl, "current_predicate(_, person(_,_)).")
println("is apple a fruit? $(boolean)")

# Open a stream in SWI-Prolog
stream::PrologStream = SWIPL2J.open_stream(swipl, filename, :append)
SWIPL2J.write(stream, "fruit(apple).\n")
SWIPL2J.write(stream, "fruit(orange).\n")
SWIPL2J.write(stream, "fruit(pear).\n")
SWIPL2J.write(stream, "fruit(strawberry).\n")

# ----------query_value------------
string::String = query_value(swipl, "stream_property(Stream, alias('$(stream.alias)'))")
println("SWI-Prolog stream: $(string)")
SWIPL2J.close(stream)

# --------query_all_values---------
# This will give an error, as `fruit` does not exist yet in SWI-Prolog
# not being consulted
list::Union{Vector{String}, Nothing} = SWIPL2J.query_all_values(swipl, "findall(X, fruit(X), L)")
println("List of all fruits before it exists (nothing): $(list)")
# Lets consult the file, then query the same thing again
SWIPL2J.consult_file(swipl, filename)
# Now we will get the results of our fruit statements
list = SWIPL2J.query_all_values(swipl, "findall(X, fruit(X), L)")
println("List of all fruits: $(list)")

# ---------query_manual------------
# Querying manually gives us a simple vector of string containing all output of that query
manual_list::Vector{String} = SWIPL2J.query_manual(swipl, "findall(X, fruit(X), L)")
println("query_manual result of finding all fruits: $(manual_list)")

# Finally, lets see what happens if a query contains a syntax error
list::Union{Vector{String}, Nothing} = SWIPL2J.query_bool(swipl, "findall(X, fruit(X), L))")
println("Result of an SWI-Prolog query with a syntax error: $(list)")

SWIPL2J.unload_file(swipl, filename)

SWIPL2J.close(swipl)
```

## Using Agents.jl

One of the primary motivations for this bridge was to enable logical agents using modern agent toolkits.

The example below isn't a particularly compelling one, but demonstrates how one may go about interfacing SWIPL2J and [Agents.jl](https://juliadynamics.github.io/Agents.jl/stable/tutorial/). Note that the Schelling example is superior solely with Agents.jl and the addition of SWIPL2J elements is solely to demonstrate how a developer may choose to integrate modern agent tool kits with logical agents.

```julia

using SWIPL2J
using Agents # Example was created on stable/tutorial v6.2.9


# make the space the agents will live in
space = GridSpace((20, 20)) # 20×20 grid cells

#Empty file
filename::String = "example.pl"
open(filename, "w")     # Create a file for the example


# make an agent type appropriate to this space and with the
# properties we want based on the ABM we will simulate
@agent struct Schelling(GridAgent{2}) # inherit all properties of `GridAgent{2}`
    group::Int # the group does not have a default value!
    swipl::Base.Process # knowledge base for mood  mood::Bool = false # all agents are sad by default :'(
end


# define the evolution rule: a function that acts once per step on
# all activated agents (acts in-place on the given agent)
function schelling_step!(agent, model)
    # Here we access a model-level property `min_to_be_happy`
    # This will have an assigned value once we create the model
    minhappy = model.min_to_be_happy
    count_neighbors_same_group = 0
    # For each neighbor, get group and compare to current agent's group
    # and increment `count_neighbors_same_group` as appropriately.
    # Here `nearby_agents` (with default arguments) will provide an iterator
    # over the nearby agents one grid cell away, which are at most 8.
    for neighbor in nearby_agents(agent, model)
        if agent.group == neighbor.group
            count_neighbors_same_group += 1
        end
    end
    # After counting the neighbors, decide whether or not to move the agent.
    # If `count_neighbors_same_group` is at least min_to_be_happy, set the
    # mood to true. Otherwise, move the agent to a random position, and set
    # mood to false.
    if count_neighbors_same_group ≥ minhappy
        SWIPL2J.write_swipl(agent.swipl, "retract(mood(X)).\n")                 # Access the KB as agent property
        SWIPL2J.write_swipl(agent.swipl, "assertz(mood(happy)).\n") #initially sad
    else
        SWIPL2J.write_swipl(agent.swipl, "retract(mood(X)).\n")
        SWIPL2J.write_swipl(agent.swipl, "assertz(mood(sad)).\n") #initially sad
        move_agent_single!(agent, model)
    end
    return
end

# Now that mood is no longer a property of the agent, we cannot leverage adf functionalities in the same way
# A nice workaround is to have we can have a model property store data for us, and update this on a step call 
# Below loops through each agent queries knowledge-base and stores aggregated info
function model_step!(model)
    model.sum_mood = 0
    for n in 1:nagents(model)
        if SWIPL2J.query_bool(model[n].swipl, "mood(happy).") #query an agents KB through the model
            model.sum_mood += 1
        end
    end

end

# make a container for model-level properties
properties = Dict(:min_to_be_happy => 3, :sum_mood => 0)

# Create the central `AgentBasedModel` that stores all simulation information
model = StandardABM(
    Schelling, # type of agents
    space; # space they live in
    agent_step! = schelling_step!, 
    model_step! = model_step!,
    properties
)



# populate the model with agents by automatically creating and adding them
# to random position in the space
for n in 1:300
    print(n)
    swipl =SWIPL2J.start_swipl()
    add_agent_single!(model; group = n < 300 / 2 ? 1 : 2, swipl)
    SWIPL2J.write_swipl(model[n].swipl, "assertz(mood(sad)).\n") #initially sad
end

# run the model for 5 steps, and collect data.
# The data to collect are given as a vector of tuples: 1st element of tuple is
# what property, or what function of agent -> data, to collect. 2nd element
# is how to aggregate the collected property over all agents in the simulation
using Statistics: mean
xpos(agent) = agent.pos[1]
mdata = [:sum_mood]
adf, mdf = run!(model, 5; mdata)


# Make sure you close the processes
# Note, even from this simple implementation you can see one of the primary drawbacks of this method
# Long close on swipl process, this is because close has a sleep(1) call
# This was added as a fix for a prior issue, future work may iron this out.
for n in 1:300
    print(n)
    SWIPL2J.close(model[n].swipl)
end
print(mdf)
print("Done")



```

