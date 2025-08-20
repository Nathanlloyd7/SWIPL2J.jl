module SWIPL2J

include("Helpers.jl")
include("PrologStreams.jl")

import Base: close, write

export echo_term,
    start_swipl,
    close,
    consult,
    unload,
    query_manual,
    query_swipl,
    query_bool,
    query_value,
    query_all_values,
    PrologStream,
    open_stream,
    write,
    save,
    save_stream

const END_PAYLOAD::String = "_SWIPL2J_SWI-PROLOG_END_OF_PAYLOAD_"
const END_OUTPUT::String = "_SWIPL2J_SWI-PROLOG_END_OF_OUTPUT_"
const END_QUERY::String = "format(user_output, '$(END_OUTPUT)~n', []), flush_output(user_output).\n"

"""
    echo_term()

Open a terminal connection.
https://docs.julialang.org/en/v1/base/io-network/

"""
function echo_term()
    if Sys.iswindows()
        #install a new OS
        cmd0 = `cmd /C echo =====================`
        cmd1 = `cmd /C echo Connected`
    elseif Sys.isunix()
        cmd0 = `echo =====================`
        cmd1 = `echo Connected`
    end

    run(cmd0)
    run(cmd1)
    run(cmd0)
end

"""
    start_swipl(file, create_file)::Union{IO, Nothing}

Open and return an SWI-Prolog instance with an open file.

# Arguments
- `file::String`: name of the file to open the SWI-Prolog context with.
- `create_file::Bool=false`: silently create the file if it doesn't exist.
"""
function start_swipl(file::String, create_file::Bool = false)
    # Convert the file path into unix-style for compatibility
    file = unix_path(file)

    # Handle non-existant file
    if !isfile(file) && !prompt_file_creation(file, create_file)
        return nothing
    end

    # Open the SWI-Prolog instance with the specified file
    if Sys.iswindows()
        swipl = open(`cmd /C "swipl -q -s $(file) --tty=false 2>&1"`, "r+")
    elseif Sys.isunix()
        # Cannot confirm if this works
        swipl = open(`sh -c "swipl -q -s $(file) --tty=false 2>&1"`, "r+")
    else
        println("Incompatible System, neither Windows or Unix.")
        swipl = nothing
    end

    # Verify that the SWI-Prolog process has opened
    if !isopen(swipl)
        error("Error: Unable to open a SWI-Prolog process.")
        return nothing
    end

    # Test that the file opened with swipl is valid
    write_swipl(swipl, "consult('$(file)').")
    result = readline(swipl)
    s = readline(swipl)  # Synchronization fix: Skip the next line after response
    if result != "true."
        error("Error: SWI-Prolog opened, but the file given could not be loaded.")
    end

    # If the file given is valid

    return swipl
end

"""
    start_swipl()

Open and returns an SWI-Prolog process.
"""
function start_swipl()
    # swipl = open(`swipl -q`, "r+")   # Open SWI-Prolog quietly without a specific file.

    if Sys.iswindows()
        swipl = open(`cmd /C "swipl -q --tty=false 2>&1"`, "r+")
    elseif Sys.isunix()
        # Cannot confirm if this works
        swipl = open(`$swipl_cmd -q --tty=false`, "r+", stderr=stdout)
    else
        println("Incompatible System, neither Windows or Unix.")
        swipl = nothing
    end

    # Verify that the SWI-Prolog process has opened.
    if !isopen(swipl)
        error("Error: Unable to open SWIPL process")
        return nothing
    end

    return swipl
end

"""
    consult(swipl, file::String, create_file::Bool = false)

Consult the file for SWI-prolog.
https://www.swi-prolog.org/pldoc/doc_for?object=consult/1

# Arguments
- `swipl`: SWI-Prolog process
- `file::String`: file to consult
- `create_file::Bool=false`: silently create the file if it doesn't exist.
"""
function consult(swipl::IO, file::String, create_file::Bool = false)
    # Convert the file path into unix-style for compatibility
    file = unix_path(file)

    if !isopen(swipl) # Early out if the SWI-Prolog instance is not open.
        error("Error: SWIPL process is not open")
        return nothing
    end

    # Ensure the file is created or return
    if !isfile(file) && !prompt_file_creation(file, create_file)
        return nothing
    end

    result = query_bool(swipl, "consult('$(file)')")

    # Ensure that the file was opened successfully.
    if !result
        error("Error: Unable to open file `$(file)` in SWI-Prolog")
    end

    return nothing
end

"""
    unload(swipl, file::String)

Unload the file as to not include its context for future queries.
https://www.swi-prolog.org/pldoc/doc_for?object=unload_file/1

# Arguments
- `swipl`: SWI-Prolog process
- `file::String`: file to unload
"""
function unload(swipl::IO, file::String)
    if !isopen(swipl) # Early out if the SWI-Prolog instance is not open.
        error("Error: SWIPL process is not open")
        return nothing
    end

    # Convert the file path into unix-style for compatibility
    file = unix_path(file)

    # If the file does not exist, we send a warning message.
    # Note: We don't need to 'return' if the file doesn't exist as SWI-Prolog returns true
    # when closing a file regardless of whether the file exists or was ever open.
    if !isfile(file)
        println("Warning: File `$(file)` does not exist in the current working directory `$(pwd())`")
    end

    result = query_bool(swipl, "unload_file('$(file)')")

    if !result
        error("Error: An error occurred while trying to unload file `$(file)` in SWI-Prolog")
        return nothing
    end

    return nothing
end

"""
    close(swipl)

Close the SWI-Prolog instance.
https://www.swi-prolog.org/pldoc/doc_for?object=halt/0

# Arguments
- `swipl`: SWI-Prolog process
"""
function close(swipl::IO)
    flush(swipl)

    if !isopen(swipl)   # Early out if the SWI-Prolog instance is already closed.
        println("SWIPL is already closed")
        return nothing
    end

    try
        Base.write(swipl, "halt.\n")     # Stop the SWI-Prolog process with `halt.`
        flush(swipl)    # Clear the output buffer
        sleep(1)
        Base.close(swipl)
    catch
        error("Error: Unable to close() SWIPL process")
    end

end

"""
    save(swipl, file::String, create_file::Bool = false)

Saves the current facts from SWI-Prologs memory into the given file.
tell: https://www.swi-prolog.org/pldoc/doc_for?object=tell/1
listing: https://www.swi-prolog.org/pldoc/doc_for?object=listing/0
told: https://www.swi-prolog.org/pldoc/doc_for?object=told/0

# Arguments
- `swipl`: SWI-Prolog process
- `file::String`: file to save SWI-Prolog's current memory to
- `create_file::Bool=false`: silently create the file if it doesn't exist.
"""
function save(swipl::IO, file::String, create_file::Bool = false)
    # Convert the file path into unix-style for compatibility
    file = unix_path(file)

    # Handle non-existent file
    if !isfile(file) && !prompt_file_creation(file, create_file)
        return nothing
    end

    result1 = query_bool(swipl, "tell('$(file)').")
    result2 = query_bool(swipl, "listing.")
    result3 = query_bool(swipl, "told.")

    # Ensure all 3 command results are successful
    if !result1 || !result2 || !result3
        error("Error: Failed to save SWI-Prolog fact memory into file.")
        return nothing
    end

    return nothing
end



# ---------------------------------------------------------------------------------------
#                               SWI-Prolog Query Functions
# ---------------------------------------------------------------------------------------

"""
    query_swipl(swipl::IO, query::String, debug::Bool=false)::NamedTuple{payload::Vector{String}, result::SubString{String}}

Sends a query to an SWI-Prolog process, returns a payload and result,
 if an error occurrs as a result of the query, the payload will house these error messages.

# Arguments
- `swipl::IO`: SWI-Prolog process
- `query::String`: query to send to SWI-Prolog
- `debug::Bool=false`: if true, prints payload.
"""
function query_swipl(swipl::IO, query::String)::@NamedTuple{payload::Vector{String}, result::SubString{String}, error::Bool}

    # println("Query: $(query)")

    Base.write(swipl, query)    # Send query to SWI-Prolog
    flush(swipl)
    Base.write(swipl, END_QUERY)    # Send ending message to SWI-Prolog to prevent read issues
    flush(swipl)

    payload = String[]
    isError = false
    errorMessagePrinted = false
    outputEnded = false
    payloadEndRead = false

    # Gather all SWI-Prolog payload response lines
    while true
        if eof(swipl)
            error("Error: End Of File reached while awaiting SWI-Prolog output.")
        end

        line = readline(swipl)

        # println("Payload line: ", line)

        if !isError && (startswith(strip(line), "ERROR: "))
            isError = true  # prevents the following result while loop from executing.
        end

        if isError && !errorMessagePrinted
            read_prolog_error_alert(query)
            errorMessagePrinted = true
        end

        if isError
            read_prolog_error_line(line)
        end

        # Skip an empty line
        if line == "" continue end

        # The payload has ended, stop reading into payload
        if line == END_PAYLOAD
            payloadEndRead = true
            break
        end

        if line == END_OUTPUT
            read_end(swipl)
            outputEnded = true
            break
        end

        push!(payload, line)

        # Last error line detection, no other lines are given by SWI-Prolog after this
        if (startswith(strip(line), "ERROR: ") && endswith(strip(line), ".")) || startswith(strip(line), "ERROR: Unknown procedure:")
            break
        end

    end

    # After the marker, the next non-empty line is typically the final status ("true."/"false." etc.)
    result = ""
    while !isError && outputEnded == false
        if eof(swipl)
            error("EOF reached while waiting for SWI-Prolog final status")
        end

        line = readline(swipl)

        # println("Result line: ", line)

        # Ensure that the end of payload clause cannot be counted as a result
        if strip(line) == END_PAYLOAD
            payloadEndRead = true
            continue
        end

        if strip(line) == END_OUTPUT
            read_end(swipl)
            outputEnded = true
            break
        end

        # SWI-Prolog typically ends its response with an empty line, were we finish reading
        if strip(line) == "" break end

        result = strip(line)
    end

    while !outputEnded
        line = readline(swipl)
        # println("Reading extra line: ", line)

        if strip(line) == END_OUTPUT
            read_end(swipl)
            outputEnded = true
        end

    end
    
    # If we have no result, non errors, and didn't encounter the payload end clause
    # then the true result must lie in the payload, typically as the last entry
    if isempty(result) && !payloadEndRead && !isError && !isempty(payload)
            result = payload[end]
    end

    # println("Final Payload: $(payload)")
    # println("Final Result: $(result)")
    # println("Final IsError: $(isError)")

    # Create a @NamedTuple type for SWI-Prolog's payload and result
    res = (payload = payload, result = result, error = isError)

    return res
end

"""
    query_manual(swipl::IO, query::String, read_until_end=true)

Sends an unmodified query to SWI-Prolog, reads and returns however many lines passed in as
the readlines parameter not including empty lines

# Arguments

- `swipl::IO`: SWI-Prolog process
- `query::String`: query to send to prolog
- `read_until_end::Bool=true`: number of lines to read after querying, ensure this number is not
greater than the number of expected lines out
the query should return
"""
function query_manual(swipl::IO, query::String, read_until_end::Bool = true)::Vector{String}

    # Validate query syntax
    if !endswith(query, ".")
        query = query * "."
    end

    if !endswith(query, "\n")
        query = query * "\n"
    end

    Base.write(swipl, query)    # Query SWI-Prolog with user query
    flush(swipl)
    Base.write(swipl, END_QUERY)    # Send ending message to SWI-Prolog to prevent read issues
    flush(swipl)

    results = String[]
    isError::Bool = false

    # Read all lines until the end of the query
    while read_until_end
        line = readline(swipl)

        if strip(line) == END_OUTPUT    # exit loop when we see our ending message
            read_end(swipl)
            break
        end

        if startswith(strip(line), "ERROR: ") && !isError
            read_prolog_error_alert(query)
            isError = true 
        end

        if isError
            read_prolog_error_line(line)
        end

        if strip(line) != "" push!(results, line) end

    end

    return results
end

"""
    query_bool(swipl::IO, query::String)::Union{Bool, Nothing}

Queries SWI-Prolog and returns the result of the query as a boolean, returns nothing if the
query did not yeild `true.`, or `false.`.

# Arguments

- `swipl::IO`: SWI-Prolog process
- `query::String`: query to send to SWI-Prolog
"""
function query_bool(swipl::IO, query::String)::Union{Bool, Nothing}

    final_query = create_query(query)
    res = query_swipl(swipl, final_query)

    # If an error occured and no result was given, return nothing
    if res.error && isempty(res.result) return nothing end

    if res.result == "true."
        return true
    elseif res.result == "false."
        return false
    else
        if !isempty(res.result)
            println("Unexpected result from SWI-Prolog: ", res.result)
        end
        return nothing
    end

end

"""
    query_value(swipl::IO, query::String)::Union{String, Nothing}

Queries SWI-Prolog and returns the result of the query as a string, returns nothing if an
error occured and the query yielded no result.

# Arguments

- `swipl::IO`: SWI-Prolog process
- `query::String`: query to send to SWI-Prolog
"""
function query_value(swipl::IO, query::String)::Union{String, Nothing}

    final_query = create_query(query)
    res = query_swipl(swipl, final_query)

    # If an error i=occured and there was no result, return nothing
    if res.error && isempty(res.result) return nothing end

    # Return the result if one was given
    if !isempty(res.result) return res.result end

    # Last resort, return the payload (this may be problematic)
    return res.payload[1]
end

"""
    query_all_values(swipl::IO, query::String)::Union{Vector{String}, Nothing}

queries SWI-Prolog and returns the results as a vector of strings. A query does not have
to return multiple results, a non-list result will be wrapped as a string inside the
vector. This function is suited for single line results

# Arguments

- `swipl::IO`: SWI-Prolog process
- `query::String`: query to send to SWI-Prolog
"""
function query_all_values(swipl::IO, query::String)::Union{Vector{String}, Nothing}

    final_query = create_query(query)
    res = query_swipl(swipl, final_query)

    # If an error occured and no result was given, return nothing
    if res.error && isempty(res.result) return nothing end

    # Test if the result is a valid prolog list, if so we return the vectorized list
    if is_prolog_list(string(res.result))
        return parse_prolog_list_line(string(res.result))
    end

    # Test if the result is valid and isnt a prolog list, if so we wrap it into a vectorized list (ex: 'true.' -> Vector{String} = ["true."])
    if !isempty(strip(res.result)) && !is_prolog_list(string(res.result))
        return [res.result]
    end
    
    # Last resort is we check the payload for a result
    for line in res.payload
        line = strip(line)
        if is_prolog_list(line)
            return parse_prolog_list_line(string(line))
        elseif !isempty(line)
            return [line]
        end

    end

    # If all fails, return nothing
    return String[]
end

end