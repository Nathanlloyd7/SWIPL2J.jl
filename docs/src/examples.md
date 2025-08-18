```@meta
CurrentModule = SWIPL2J
```

## Basics

Open an SWI-Prolog process with `start_swipl`, this will return an SWI-Prolog object for that process

```julia
swipl = SWIPL2J.start_swipl()
```

`start_swipl` also accepts a file to consult after opening

```julia
swipl = SWIPL2J.start_swipl("example.pl")
```

To close an SWI-Prolog process, call `close` and pass in the SWI-Prolog object

```julia
SWIPL2J.close(swipl)
```

To save SWI-Prolog memory into a file, use `save` with the SWI-Prolog object and a file name. Saving SWI-Prologs memory to a file overwrites any data that file previously had

```julia
SWIPL2J.save(swipl, "example.pl")
```

Consult a file with `consult_file` so that the file can be queried

```julia
SWIPL2J.consult_file(swipl, "example.pl")
```

To unload a consulted file, call `unload_file`

```julia
SWIPL2J.unload_file(swipl, "example.pl")
```

Full example of a basic SWI-Prolog interaction

```julia
swipl = SWIPL2J.start_swipl()   # Open a SWI-Prolog process

SWIPL2J.consult_file(swipl, "example.pl")   # Consult a file, so we can query it

# Send a query to the SWI-Prolog process
# TODO: When we make a proper function to write/query to swipl, I will add a line here

SWIPL2J.unload_file(swipl, "example.pl")    # Unload the file since we no longer need it

SWIPL2J.close(swipl)    # Close the SWI-Prolog process
```

## SWI-Prolog Streams

Open and get an SWI-Prolog stream by passing an SWI-Prolog object, and a file name into `open_stream`

```julia
stream = SWIPL2J.open_stream(swipl, "example.pl")
```

`open_stream` accepts other parameters, such as *mode*, *automatically create a file*, and an *alias*

Here is the creation of a stream with *append* mode, *automatic file creation* set to **true**, and the *alias* "new_stream"

```julia
stream = SWIPL2J.open_stream(swipl, "example.pl", :append, true, "new_stream")
```

To close a stream, use `close`

```julia
SWIPL2J.close(stream)
```

To write into a stream, use `write` with the stream object, and the message to be written or appended into the file

```julia
SWIPL2J.write(stream, "fruit(apple).\n")
```

Save operations of a stream with `save`

```julia
SWIPL2J.save(stream)
```

### SWI-Prolog stream full example

```julia
swipl = SWIPL2J.start_swipl()   # Open a SWI-Prolog process

# Open a stream in append mode
stream = SWIPL2J.open_stream(swipl, "example.pl", :append)

# Append some text to the file
SWIPL2J.write(stream, "fruit(apple).\n")
SWIPL2J.write(stream, "fruit(pear).\n")

SWIPL2J.close(stream)    # Unload the file since we no longer need it

SWIPL2J.close(swipl)    # Close the SWI-Prolog process
```