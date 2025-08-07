
"""
    try_create_file(file::String, dir::String)::Bool

Attempts to create a file at the given directory, returns a boolean status of the file creation.

# Arguments
- `file::String`: file to create
"""
function try_create_file(file::String)::Bool
    try
        open(file, "w")
        return isfile(file)
    catch e
        println("Error: Could not create file: ", e)
        return false;
    end

end

"""
    prompt_file_creation(file::String, create_file::Bool = false)::Bool

Helper loop to ask prompt the user to create a file.

# Arguments
- `file::String`: file to create
- `create_file::Bool=false`: silently create the file if it doesn't exist
"""
function prompt_file_creation(file::String, create_file::Bool = false)::Bool
    if !isinteractive()
        println("Warning: Non-interactive environment, cannot prompt file creation.")
        return false
    end
    
    while !create_file
        print("File `$(file)` does not exist. Would you like to create it? [y/n]: ")
        answer = readline()

        if lowercase(answer) == "n"
            println("File not created, no SWI-Prolog instance was opened.")
            return false
        elseif lowercase(answer) == "y"
            create_file = true
        else lowercase(answer) != "y" && lowercase(answer) != "n"
            println("Invalid input.")
        end

    end

    return try_create_file(file)
end

"""
    write_swipl(swipl, query::String)::Nothing

(Incomplete Function) Write a line to an SWI-Prolog process.

# Arguments
- `swipl`: SWI-Prolog process
- `query::String`: message to be written to the SWI-Prolog process.
"""
function write_swipl(swipl, query::String)
    Base.write(swipl, query)
    Base.write(swipl, "\n")
    flush(swipl)
    return nothing
end

"""
    unix_path(path::String)::String

Replaces `\\` with `/` to prevent pathing errors

# Arguments
- `path::String`: file path
"""
function unix_path(path::String)::String
    return replace(path, "\\" => "/")
end