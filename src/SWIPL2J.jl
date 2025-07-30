module SWIPL2J

export echo_term, start_swipl, launch_swipl, close_swipl

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

# =====================================================================
# Close a SWIPL connection
# =====================================================================
function close_swipl(swipl)
    flush(swipl)

    
    if !isopen(swipl)   # Early out if swipl is already closed.
        println("SWIPL is already closed")
        return nothing
    end

    try
        write(swipl, "halt.\n") # Stop the SWIPL process
        flush(swipl) # Clear the output buffer
        sleep(1)
        close(swipl)
        println("SWIPL CLOSED\n")
    catch
        error("Error: Unable to close() SWIPL process")
    end

end

end