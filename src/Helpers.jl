
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

"""
    is_prolog_list(string::String):Bool

returns whether a given string is a prolog list of the form `list = [...]`.

# Arguments

- `string::String`: the string to be determined if it is a list
"""
function is_prolog_list(string::String)::Bool
    string = strip(string)

    equal_pos = findfirst('=', string)
    if equal_pos === nothing return false end

    if length(string) < equal_pos + 2 || string[equal_pos + 2] != '[' return false end

    return endswith(string, "]") || endswith(string, "].")
end

"""
    parse_prolog_list_line(string::String)::Vector{String}

parses an SWI-Prolog list into a vecctor of strings.

# Arguments

- `string::String`: a list as a string
"""
function parse_prolog_list_line(string::String)::Vector{String}
    # Ensure the string has the structure [ ... ], Return empty otherwise
    m = match(r"\[([^\]]*)\]", string)
    if m === nothing
        return String[]
    end

    # Get the string inside the '[' and ']', return if its empty
    contents = m.captures[1]
    if isempty(strip(contents))
        return String[]
    end

    # Initialize loop variables
    items = String[]
    current_item = ""
    in_single_quotes = false
    in_double_quotes = false

    # This loop ensures commas in a Prolog variable aren't mistaken as delimiters
    for char in contents
        if char == '\'' && !in_double_quotes    # Alert current variable that `'` exists inside
            in_single_quotes = !in_single_quotes
            current_item *= char
        elseif char == '"' && !in_single_quotes     # Alert current variable that `"` exists inside
            in_double_quotes = !in_double_quotes
            current_item *= char
        # If a comma is found while not in quotes, we end the item
        elseif char == ',' && !in_single_quotes && !in_double_quotes
            item_str = strip(current_item)
            if !isempty(item_str)
                push!(items, item_str)
            end
            current_item = ""
        else    # A comma is found while in quotes, add it to the item
            current_item *= char
        end
    end

    last_item = strip(current_item)
    if !isempty(last_item)
        push!(items, last_item)
    end

    return items
end

"""
    create_query(query::String)::String

Turns the given string into a standardized query equipped to handle payload and final result.

https://www.swi-prolog.org/pldoc/doc_for?object=writeln/1
https://www.swi-prolog.org/pldoc/doc_for?object=flush_output/0

# Arguments

- `query::String`: a string which will be converted into a larger query
"""
function create_query(query::String)::String

    if endswith(query, "\n") query = chomp(query) end

    # Remove any `.` or `,` at the end of a query
    if endswith(strip(query), ".") || endswith(strip(query), ",") query = chop(query) end

    query = query * ", writeln('$(END)'), flush_output.\n"
    return query
end