module SWIPL2J

include("Helpers.jl")

export echo_term
export start_swipl
export close
export consult_file
export unload_file

export PrologStreams

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
    swipl = open(`swipl -q`, "r+")   # Open SWI-Prolog quietly without a specific file.

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

    # Tell SWI-Prolog to consult the given file.
    write_swipl(swipl, "consult('$(file)').")
    result = readline(swipl)
    s = readline(swipl)  # Synchronization fix: Skip the next line after response
    # println("consult file: ", result)

    # Ensure that the file was opened successfully.
    if result != "true."
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

    # Tell SWI-Prolog to unload the given file.
    write_swipl(swipl, "unload_file('$(file)').")
    result = readline(swipl)
    s = readline(swipl)  # Synchronization fix: Skip the next line after response

    # Ensure that the file was unloaded successfully
    # println("unload file result '$(file)': ", result)
    if result != "true."
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
        println("Closing SWI-Prolog.")
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

    # Create and execute the tell, listing, and told command. This fully writes to the file
    prolog_command = "tell('$(file)')."
    write_swipl(swipl, prolog_command)
    result1 = readline(swipl)
    s = readline(swipl)  # Synchronization fix: Skip the next line after response

    prolog_command = "listing."
    write_swipl(swipl, prolog_command)
    result2 = readline(swipl)
    s = readline(swipl)  # Synchronization fix: Skip the next line after response

    prolog_command = "told."
    write_swipl(swipl, prolog_command)
    result3 = readline(swipl)
    s = readline(swipl)  # Synchronization fix: Skip the next line after response

    # println("Result of saving stream: ", result3)
    # Ensure all 3 command results are successful
    if result1 != "true." || result2 != "true." || result3 != "true."
        error("Error: Failed to save SWI-Prolog fact memory into file.")
        return nothing
    end

    return nothing
end

end