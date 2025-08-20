```@meta
CurrentModule = SWIPL2J
```

## SWIPL2J Examples


### Basic stream, consulting, and querying example

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

### Querying

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



