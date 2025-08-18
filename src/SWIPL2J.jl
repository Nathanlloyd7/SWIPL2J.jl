module SWIPL2J

include("Helpers.jl")

export echo_term
export start_swipl
export close
export consult_file
export unload_file

export PrologStreams

export query_manual
export query_swipl
export query_bool
export query_value
export query_all_values

const END::String = "_SWIPL2J_SWI-PROLOG_END_OF_PAYLOAD_"

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
    start_swipl(file, create_file)

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
    swipl = open(`swipl -q -s $(file)`, "r+")

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
    consult_file(swipl, file::String, create_file::Bool = false)

Consult the file for SWI-prolog.
https://www.swi-prolog.org/pldoc/doc_for?object=consult/1

# Arguments
- `swipl`: SWI-Prolog process
- `file::String`: file to consult
- `create_file::Bool=false`: silently create the file if it doesn't exist.
"""
function consult_file(swipl, file::String, create_file::Bool = false)
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
    unload_file(swipl, file::String)

Unload the file as to not include its context for future queries.
https://www.swi-prolog.org/pldoc/doc_for?object=unload_file/1

# Arguments
- `swipl`: SWI-Prolog process
- `file::String`: file to unload
"""
function unload_file(swipl, file::String)
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
function close(swipl)
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
function save(swipl, file::String, create_file::Bool = false)
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

# QUERY_SWIPL_NO_PAYLOAD is a dictionary of known SWI-Prolog calls which may prevent the
# payload end clause `_END_PAYLOAD_` from being written to the terminal. Since our
# program reads until the `_END_PAYLOAD_` clause is found, this prevents reading too far
const QUERY_SWIPL_NO_PAYLOAD::Dict{String, Tuple{String, Bool}} = Dict(
    "stream_property" => ("payload", false),
    "tell" => ("payload", false),
    "listing" => ("payload", false),
)

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

    doPayload = true

    # Ensure query isn't calling a Prolog function that can prevent the payload end clause
    for (predicate, (type, flag)) in QUERY_SWIPL_NO_PAYLOAD
        # Regex check to prevent false positives
        regex = Regex("^\\s*$(predicate)\\s*(\\.|\\(|,)")
        if occursin(regex, query) && type == "payload" && !flag
            doPayload = false
            break
        end

    end

    # Send query to SWI-Prolog
    Base.write(swipl, query)
    flush(swipl)

    payload = String[]
    isError = false
    errorMessagePrinted = false

    # Gather all SWI-Prolog payload response lines
    while doPayload
        if eof(swipl)
            error("Error: End Of File reached while awaiting SWI-Prolog output.")
        end

        line = readline(swipl)

        if !isError && (startswith(strip(line), "ERROR: "))
            isError = true  # prevents the following result while loop from executing.
        end

        if isError && !errorMessagePrinted
            println()
            println("\033[1;38;5;208mSWI-Prolog Error For Query:\033[0m $(chomp(query))")
            errorMessagePrinted = true
        end

        if isError
            println("\033[1;33mSWI-Prolog Error:\033[0m $(line)")
        end



        # Skip an empty line
        if line == "" continue end

        # The payload has ended, stop reading into payload
        if line == END break end

        push!(payload, line)

        # Last error line detection, no other lines are given by SWI-Prolog after this
        if (startswith(strip(line), "ERROR: ") && endswith(strip(line), ".")) || startswith(strip(line), "ERROR: Unknown procedure:")
            break
        end

    end

    # After the marker, the next non-empty line is typically the final status ("true."/"false." etc.)
    result = ""
    while !isError
        if eof(swipl)
            error("EOF reached while waiting for SWI-Prolog final status")
        end

        line = readline(swipl)

        # Ensure that the end of payload clause cannot be counted as a result
        if !doPayload && strip(line) == END 
            continue
        end

        # SWI-Prolog typically ends its response with an empty line, were we finish reading
        if strip(line) == "" break end

        result = strip(line)
    end

    # Create a @NamedTuple type for SWI-Prolog's payload and result
    res = (payload = payload, result = result, error = isError)

    return res
end

"""
    query_manual(swipl::IO, query::String, read_lines=0)

Sends an unmodified query to SWI-Prolog, reads and returns however many lines passed in as
the readlines parameter not including empty lines

# Arguments

- `swipl::IO`: SWI-Prolog process
- `query::String`: query to send to prolog
- `read_lines::Int=0`: number of lines to read after querying if you know how many lines
the query should return
"""
function query_manual(swipl::IO, query::String, read_lines::Int = 0)::Union{Vector{String}, Nothing}

    # Validate query syntax
    if !endswith(query, ".")
        println("Warning: Query `$(query)` may not have correct syntax.")
    end

    if !endswith(query, "\n")
        query = query * "\n"
    end

    # Send query to SWI-Prolog
    Base.write(swipl, query)
    flush(swipl)

    if read_lines == 0 return nothing end

    results = String[]

    for i in 1:read_lines
        line = readline(swipl)
        println("Line $(i-1): $(line)")
        if !isempty(strip(line)) push!(results, line) end
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
        println("Unexpected result from SWI-Prolog: ", res.result)
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

    # Last restort, return the payload (this potentially should be removed)
    return res.payload[1]
end

"""
    query_all_values(swipl::IO, query::String)::Union{Vector{String}, Nothing}

queries SWI-Prolog and returns the results as a vector of strings. A query does not have
to return multiple results, a non-list result will be wrapped as a string inside the
vector.

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