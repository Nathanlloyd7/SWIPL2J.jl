```@meta
CurrentModule = SWIPL2J
```

# SWIPL2J

Documentation for [SWIPL2J](https://github.com/nathanlloyd7/SWIPL2J.jl).

SWIPL2J is an API for Julia to interface with SWI-Prolog, providing easy integration between Julia and the logic of Prolog.

## Getting started

### Basics

To open an SWI-Prolog process, call `SWIPL2J.start_swipl`, you can also pass in a file to consult once opening

```julia
swipl::IO = SWIPL2J.start_swipl()
# or
swipl::IO = SWIPL2J.start_swipl("example.pl")
```

To close an existing SWI-Prolog process, call `close` and pass in the SWI-Prolog object

```julia
SWIPL2J.close(swipl)
```

Use `SWIPL2J.save` to save SWI-Prolog's memory to a file

```julia
# Note: will over-write existing file contents
SWIPL2J.save(swipl, "example.pl")
```

Consult a file with `SWIPL2J.consult_file` so that the file can be queried

```julia
SWIPL2J.consult_file(swipl, "example.pl")
```

To unload a consulted file, call `SWIPL2J.unload_file`

```julia
SWIPL2J.unload_file(swipl, "example.pl")
```

### SWI-Prolog Querying

There are 4 functions to query SWI-Prolog, `query_bool`, `query_value`, `query_all_values`, and `query_manual`

`query_bool` returns the result of the query as a boolean, if the result is not true or
false the function returns nothing
```julia
result::Union{Bool, Nothing} = SWIPL2J.query_bool(swipl, "fruit(apple).")
# Expected result:
#   result = true               if fruit exists and apple is a fruit
#   result = false              if fruit exists and apple is not a fruit
#   result = nothing            if fruit does not exist
```

`query_value` returns the string result of the query, if the result was an error the
function returns nothing
```julia
result::Union{String, Nothing} = SWIPL2J.query_value(swipl, "stream_property(Stream, alias('stream_1'))")
# Expected result:
#   result = "Stream = <stream>(...)"   if the stream exists
#   result = "false."                   if the stream does not exist
```

`query_all_values` returns the vector of strings resulting from the query, if the result was an error the
function returns nothing
```julia
result::Union{Vector{String}, Nothing} = SWIPL2J.query_all_values(swipl, "findall(X, fruit(X), L)")
# Expected result:
#   result = ["apple", ...]     for apple, and any other fruits that exist
#   result = nothing            if fruit does not exist
```

`query_manual` returns the vector of strings resulting from the query, if the result was an error the
function returns nothing
```julia
result::Union{Vector{String}, Nothing} = SWIPL2J.query_all_values(swipl, "pwd()")
# Result:
#   result = ["<working directory>", "true."]
```

It's important to note the difference between a payload and a result.

```julia
query_value(swipl, "pwd()")         # Result: "true."
query_all_values(swipl, "pwd()")    # Result: ["true."]
```
You may expect either line in the above code to return the working directory as a string (or a string in a
vector in the case of `query_all_values`), however since SWI-Prolog outputs the working directory as a
payload, the working directory will not be present in either results, in this case you may
want to use `query_manual` and then take the line you know will contain the working directory. In contrast
SWI-Prolog will return a stream as a result, not a payload
```julia
query_value(swipl, "stream_property(Stream, alias('TestStream'))")
#   Result: "Stream = <stream>(...)."
query_all_values(swipl, "stream_property(Stream, alias('TestStream'))")
#   Result: ["Stream = <stream>(...)."]
```

### SWI-Prolog Streams

To open a stream, call `SWIPL2J.open_stream` with an SWI-Prolog process and a file
```julia
stream = SWIPL2J.open_stream(swipl, "example.pl")
```

To write into a stream, use `write` with the stream object, and the message to be written or appended into the file
```julia
SWIPL2J.write(stream, "fruit(apple).\n")
```

To close a stream, use `SWIPL2J.close` with the stream
```julia
SWIPL2J.close(stream)
```

Save operations of a stream with `SWIPL2J.save`
```julia
SWIPL2J.save(stream)
```

# TODO List

- As we are using the terminal, large outputs may be truncated due to limited buffer size, we need utility functions to query the current buffer size (increase of decrease buffer size maybe?) and evaluate outputs as to whether they contain the `...` or elipses that signals that the output has been truncated
- More examples of varying length
- Translate to a Python package
- Refer to published work using this package
- Alternatives to SWIPL? Can we take advantage of more performant Prolog environments
- Performance compare herbswipl and julog
- Can we integrate with herbswipl and julog - default to SWIPL2J when, for example, using nested infix operators?
- Use a structure for a swipl process, a property of this structure being a vector of streams.
- Can we safely remove sleep(1) in close()? Vastly decreases performance.
