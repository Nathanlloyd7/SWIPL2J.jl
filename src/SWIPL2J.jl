module SWIPL2J

# =====================================================================
# Opening A Terminal connection
#   https://docs.julialang.org/en/v1/base/io-network/
# =====================================================================
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
        
# =====================================================================
# Opening A SWIPL connection
#   https://docs.julialang.org/en/v1/base/io-network/
# =====================================================================
# --quiet or -q flag launches without banner/welcome message
function start_swipl(file)
    return open(`swipl -q -s $(file)`, "r+")
end

function launch_swipl(file)
    sleep(1.5)
    swipl = start_swipl(file)
    flush(swipl)
    return swipl
end
# =====================================================================
# Closing a SWIPL connection
# =====================================================================
function close_swipl(swipl)
    flush(swipl)
    if isopen(swipl)
        try
            write(swipl, "halt.\n") #stop swipl
            flush(swipl) #clear output stream
            sleep(1) #I would sometimes get an I/O error without this, not sure if it is needed now
            close(swipl)
            println("SWIPL CLOSED\n")
        catch
            error("Error: Unable to close() SWIPL process")
        end
    else
        println("SWIPL is already closed")
    end
end
# =====================================================================
# Core
# =====================================================================
function write_swipl(swipl, query)
    #print(" ", query) # <--- good for debugging
    write(swipl, query)
    write(swipl, "\n")
    flush(swipl)
end
# =====================================================================
# Query
# =====================================================================
function query_single_output(swipl, query)
    results = []
    write_swipl(swipl, query*"\n")
    result = readline(swipl)

    if result == "false."
        readline(swipl)
    end
    push!(results, result)
    return results
end

# Known Limitation:
# Let's say you have a query that could return N items
# q = "findall((X,Y), happens(X, Y), Xs)."
# a= query_multi_output(model[6].swipl, q)
# "Xs = [(who_met(2), 2), (calc_prev(2), 2), (exp_form(2), 2), (who_met(3), 3), (calc_prev(3), 3), (exp_form(3), 3), 
# (who_met(4), 4), (calc_prev(...), 4), (..., ...)|...]."]
# The end here, because it comes to us as a string, is problematic.

# TO DO: RECTIFY THIS SO ALL ARE RETURNED, buffer size mods? swipl params?

function query_multi_output(swipl, query)
    if !occursin("findall(", query)
        error("The string does not contain `findall(`")
    end
    results = []
    write_swipl(swipl, query*"\n")
    result = readline(swipl)
    if result == "false."
        readline(swipl)
    end
    readline(swipl)
    push!(results, result)
    return results
end



# Note that this will break if multiple values of a variable are returned;
# Swipl terminal is expecting user input to cycle through 
# query_single_output(swipl, "findall(E, holdsAt(emp_exp_rule(employee(_, company), E), 2), Es).") the findall is a way to avoid hanging on multiple values of a variable

# =====================================================================
# Assert_swipl
# =====================================================================
function assert_swipl(swipl, assert)
    if last(strip(assert)) == '.'
        try
            write_swipl(swipl, assert)
            success = readline(swipl) #returns "true." or "false." after assertz
            if success == "true."
                #do nothing
            elseif success == "false."
                error("Unable to assert: ", assert, ".\nPlease check that your predicate is correct")
            elseif strip(success) == ""
                error("Unexpected error: nothing was returned")
            else
                error(assert, "<-- Was unable to assert")
            end
            readline(swipl) #returns blank line
        catch
            error("Unexpected error: You should not make it here ", assert)
        end
    else
        error("No trailing '.' found on assertz, please follow swipl syntax")
    end
end

# =====================================================================
# Cleaunp and checking
# =====================================================================
# I want a function that looks for any zombie and/or orphan swipl processes to Cleaunp
# function 1 finds counts and locations (monitor)

# function 2 takes in counts and locations to delete them (address)

# =====================================================================
# TEST
# =====================================================================

function start_close()
    echo_term()
    s = open(`swipl`)
    close_swipl(s)
end

function open_close()
    FILE = `Repos/SWIPL2J/test.pl`
    s = launch_swipl(FILE)
    close_swipl(s)
end

#open_close()
#FILE = `Repos/SWIPL2J/test.pl`
#s = launch_swipl(FILE)
#r = query_single_output(s, "fruit(X).")
#readline(s) #needed
#w = query_single_output(s, "fruits(X).")
#close_swipl(s)
#print(r, " ", w)


end
