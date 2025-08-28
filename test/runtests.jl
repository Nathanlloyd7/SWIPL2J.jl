using Revise
using Test

# ===== Comment 7th August - Nathan Lloyd 
# Package will not build nor tests run.
# The changes below to call the PrologStreams.jl file as an include as opposed to a module allow for tests to run

# However two tests appear to fail - Prolog initialisation for a script_file
# Another prolog stream test didn't work, added in a missing close 
# ===============================

# include("../src/PrologStreams.jl")

if !isdefined(@__MODULE__, :SWIPL2J)
    using SWIPL2J
end

# Global variable used to skip tests if swipl is not recognized as a PATH variable
const SKIP_TESTS::Bool = Sys.which("swipl") === nothing

if SKIP_TESTS println("Some tests will be skipped due to incompatibility.") end

if !SKIP_TESTS
@testset "SWIPL2J" begin

    # Test the "open(`swipl`)" command to ensure Julia can launch SWI-Prolog.
    # This test uses only the built in functionality of Julia to check if SWI-Prolog can be launched.
    @testset "swipl" begin
        try
            swipl = open(`swipl -q`)
            @test isopen(swipl)
            Base.close(swipl)
        catch e
            @test false
        end
        
    end

    # Test the echo_term function for any errors.
    @testset "echo_term" begin
        try
            SWIPL2J.echo_term()
            @test true
        catch e
            println(e)
            @test false
        end

    end

    # start_swipl with a file parameter
    @testset "start_swipl" begin
        file = joinpath(pwd(), "test.pl")

        open(file, "w") do io end   # Create the file, do io and close it to prevent resource lock
        sleep(1)    # Bad Fix: Sleep prevents swipl from not recognizing the file

        try
            swipl = SWIPL2J.start_swipl(file, false)
            @test isopen(swipl)
            Base.close(swipl)
        catch e
            println(e)
            @test false
        end

        sleep(1)    # Bad Fix: Sleep prevents the test from throwing an error

        if isfile(file)
            rm(file; force = true)
        end

    end

    # Test start_swipl without any parameters
    @testset "start_swipl" begin
        try
            swipl = SWIPL2J.start_swipl()
            @test isopen(swipl)

            Base.close(swipl)
        catch e
                println(e)
            @test false
        end

    end

    # Ensure close_swipl closes the given SWI-Prolog process.
    @testset "close_swipl" begin
        try
            swipl = SWIPL2J.start_swipl()
            SWIPL2J.close(swipl)
            @test !isopen(swipl)
        catch e
            println(e)
            @test false
        end

    end
    
    @testset "consult" begin
        mktemp() do path, io
            try
                Base.close(io)
                unixpath = replace(path, "\\" => "/")

                swipl = SWIPL2J.start_swipl()
                # Consult the test file, method throws an error if a prolog error occurs
                SWIPL2J.consult(swipl, unixpath, true)

                SWIPL2J.close(swipl)
                @test true
            catch e
                print(e)
                @test false
            end

        end

    end

    @testset "unload" begin
        mktemp() do path, io
            Base.close(io)
            unixpath = replace(path, "\\" => "/")

            try
                swipl = SWIPL2J.start_swipl()
                SWIPL2J.consult(swipl, unixpath, true)

                # Unload the file after consulting it, this will throw an error if Prolog does
                SWIPL2J.unload(swipl, unixpath)

                SWIPL2J.close(swipl)
                @test true
            catch e
                print(e)
                @test false
            end
            
        end

    end

    @testset "save" begin
        mktemp() do path, io
            Base.close(io)
            unixpath = replace(path, "\\" => "/")

            swipl = SWIPL2J.start_swipl()
            SWIPL2J.query_manual(swipl, "assertz(fruit(strawberry)).")
            SWIPL2J.save(swipl, unixpath, true)
            SWIPL2J.close(swipl)

            # Ensure the statement written to SWI-Prolog memory is now in the file
            @test occursin("fruit(strawberry).", read(path, String))
        end

    end


    @testset "query_swipl" begin
        swipl = SWIPL2J.start_swipl()

        # Expected output: empty payload, result is "true."
        result::@NamedTuple{payload::Vector{String}, result::SubString{String}, error::Bool} = SWIPL2J.query_swipl(swipl, SWIPL2J.create_query("assertz(fruit(banana))"))
        @test isempty(result.payload) && result.result == "true." && !result.error

        # Expected output: empty payload, result is "true"
        result = SWIPL2J.query_swipl(swipl, SWIPL2J.create_query("stream_property(Stream, alias('non-existant-stream'))"))
        @test !isempty(result.payload) && result.result == "false." && !result.error

        # Send a query with incorrect syntax
        result = SWIPL2J.query_swipl(swipl, SWIPL2J.create_query("open_stream('demo.pl', append, _, [alias('stream1')])"))
        @test occursin("ERROR: Unknown procedure", result.payload[1]) && isempty(result.result) && result.error

        SWIPL2J.close(swipl)
    end

    @testset "query_bool" begin
        swipl = SWIPL2J.start_swipl()

        # Test basic use
        @test SWIPL2J.query_bool(swipl, "assertz(fruit(apple))") == true
        @test SWIPL2J.query_bool(swipl, "fruit(apple)") == true
        @test SWIPL2J.query_bool(swipl, "fruit(banana)") == false

        # Test error handling
        a = SWIPL2J.query_bool(swipl, "open_stream('demo.pl', append, _, [alias('stream1')])")
        @test a === nothing

        SWIPL2J.close(swipl)
    end

    @testset "query_value" begin
        swipl = SWIPL2J.start_swipl()

        out = query_bool(swipl, "open('demo.pl', append, _, [alias('stream1')])")

        # Basic use-case test
        @test contains(query_value(swipl, "stream_property(Stream, alias('stream1'))"), "Stream = ")

        # Test with an expected boolean output from SWI-Prolog
        @test query_value(swipl, "assertz(fruit(apple)).") == "true."

        # Test with a syntax error (extra `)`), should return nothing
        @test query_value(swipl, "fruit(banana)).") === nothing

        SWIPL2J.close(swipl)
    end

    @testset "query_all_values" begin
        swipl = SWIPL2J.start_swipl()

        # First, set some facts
        query_bool(swipl, "assertz(fruit(banana))\n")
        query_bool(swipl, "assertz(color(banana, yellow))\n")

        # Test with a single output
        @test query_all_values(swipl, "findall(C, color(banana, C), L)") == ["yellow"]

        query_bool(swipl, "assertz(color(banana, green))\n")
        query_bool(swipl, "assertz(color(banana, brown))\n")

        # Test with multiple outputs
        @test query_all_values(swipl, "findall(C, color(banana, C), L)") == ["yellow", "green", "brown"]

        query_bool(swipl, "assertz(color(banana, ',rare ,a'))\n")

        # Test with a tricky character occurence
        @test query_all_values(swipl, "findall(C, color(banana, C), L)") == ["yellow", "green", "brown", "',rare ,a'"]

        # Test with a syntax error (missing `,` in between `banana` and `C`)
        @test query_all_values(swipl, "findall(C, color(banana C), L)") === nothing

        SWIPL2J.close(swipl)
    end

    @testset "query_manual" begin
        swipl = SWIPL2J.start_swipl()

        # Test basic functionality
        @test query_manual(swipl, "assertz(fruit(banana)).") == ["true."]

        # Test more advanced
        @test query_manual(swipl, "findall(X, fruit(X), L).") == ["L = [banana]."]

        # Test with a syntax error
        @test contains((query_manual(swipl, "findall(X, fruit(X) L)."))[1], "ERROR: Syntax error: Operator expected")

        SWIPL2J.close(swipl)
    end
    
end

else println("Skipping SWIPL2J tests due to an incompatibility.") end

if !SKIP_TESTS 
@testset "PrologStreams" begin
    # Test that open_streams opens a stream
    @testset "open_stream" begin
        mktemp() do path, io
            Base.close(io)
            unixpath = replace(path, "\\" => "/")

            try
                swipl = SWIPL2J.start_swipl()
                stream::PrologStream = SWIPL2J.open_stream(swipl, unixpath, :append, true, "TestStream1")
                @test isopen(stream.swipl) && stream.filename == unixpath && (stream.mode == :append) && stream.alias == "TestStream1"
                SWIPL2J.close(stream)
                Base.close(swipl)
            catch e
                print(e)
                @test false
            end

        end

    end

    @testset "close_stream" begin
        mktemp() do path, io
            Base.close(io)
            unixpath = replace(path, "\\" => "/")

            try
                swipl = SWIPL2J.start_swipl()
                stream::PrologStream = SWIPL2J.open_stream(swipl, unixpath, :append, true, "TestStream: close_stream.")

                SWIPL2J.close(stream)
                Base.close(swipl)
                @test true
            catch e
                print(e)
                @test false
            end

        end

    end

    @testset "write" begin
        mktemp() do path, io
            Base.close(io)
            unixpath = replace(path, "\\" => "/")

            swipl = SWIPL2J.start_swipl()

            # Open stream in write mode
            stream::PrologStream = SWIPL2J.open_stream(swipl, unixpath, :write, true, "TestStream `write`")
            SWIPL2J.write(stream, "\nfruit(blueberry).")
            SWIPL2J.close(stream)

            # Open stream in append mode
            stream = SWIPL2J.open_stream(swipl, unixpath, :append, true, "TestStream `append`")
            SWIPL2J.write(stream, "\nfruit(strawberry).")
            SWIPL2J.close(stream)

            # Open stream in read mode, should throw error
            stream = SWIPL2J.open_stream(swipl, unixpath, :read, true, "TestStream `read`")
            @test_throws ErrorException SWIPL2J.write(stream, "\nfruit(strawberry).")
            SWIPL2J.close(stream)

            Base.close(swipl)

            # Ensure the writes made it to the file
            @test occursin("fruit(blueberry).", read(path, String))
            @test occursin("fruit(strawberry).", read(path, String))

        end

    end

    @testset "save_stream" begin
        mktemp() do path, io
            Base.close(io)
            unixpath = replace(path, "\\" => "/")

            # Open, write, and save a statement to the file
            swipl = SWIPL2J.start_swipl()
            stream::PrologStream = SWIPL2J.open_stream(swipl, unixpath, :append, true, "TestStream save")
            SWIPL2J.write(stream, "\nfruit(raspberry).")
            SWIPL2J.save_stream(stream)
            SWIPL2J.close(stream)
            Base.close(swipl)

            # test the statement exists in the file
            @test occursin("fruit(raspberry).", read(path, String))
        end

    end

end
else println("Skipping PrologStreams tests due to an incompatibility.") end