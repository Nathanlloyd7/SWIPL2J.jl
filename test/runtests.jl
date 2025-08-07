using Revise
using Test

if !isdefined(@__MODULE__, :SWIPL2J)
    using SWIPL2J
end

if !isdefined(@__MODULE__, :PrologStreams)
    using PrologStreams
end

@testset "SWIPL2J" begin
    # Test the "open(`swipl`)" command to ensure Julia can launch SWI-Prolog.
    # This test uses only the built in functionality of Julia to check if SWI-Prolog can be launched.
    @testset "swipl" begin
        try
            swipl = open(`swipl -q`)
            Base.close(swipl)
            @test true
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

    # Ensure start_swipl with a file parameter
    @testset "start_swipl" begin
        mktemp() do path, io
            Base.close(io)
            unixpath = replace(path, "\\" => "/")

            swipl = SWIPL2J.start_swipl(unixpath)

            @test isopen(swipl)

            Base.close(swipl)
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
    
    @testset "consult_file" begin
        mktemp() do path, io
            try
                Base.close(io)
                unixpath = replace(path, "\\" => "/")

                swipl = SWIPL2J.start_swipl()
                # Consult the test file, method throws an error if a prolog error occurs
                SWIPL2J.consult_file(swipl, unixpath, true)

                SWIPL2J.close(swipl)
                @test true
                catch e
                print(e)
                @test false
            end

        end

    end

    @testset "unload_file" begin
        mktemp() do path, io
            Base.close(io)
            unixpath = replace(path, "\\" => "/")

            try
                swipl = SWIPL2J.start_swipl()
                SWIPL2J.consult_file(swipl, unixpath, true)

                # Unload the file after consulting it, this will throw an error if Prolog does
                SWIPL2J.unload_file(swipl, unixpath)

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
            SWIPL2J.write_swipl(swipl, "assertz(fruit(strawberry)).")
            SWIPL2J.save(swipl, unixpath, true)
            SWIPL2J.close(swipl)

            # Ensure the statement written to SWI-Prolog memory is now in the file
            @test occursin("fruit(strawberry).", read(path, String))
        end

    end
    
end

@testset "PrologStreams" begin
    # Test that open_streams opens a stream
    @testset "open_stream" begin
        mktemp() do path, io
            Base.close(io)
            unixpath = replace(path, "\\" => "/")

            try
                swipl = SWIPL2J.start_swipl()
                stream = PrologStreams.open_stream(swipl, unixpath, :append, true, "TestStream1")
                @test isopen(stream.swipl) && stream.filename == unixpath && (stream.mode == :append) && stream.alias == "TestStream1"
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
                stream = PrologStreams.open_stream(swipl, unixpath, :append, true, "TestStream: close_stream.")

                PrologStreams.close(stream)
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
            stream = PrologStreams.open_stream(swipl, unixpath, :write, true, "TestStream `write`")
            PrologStreams.write(stream, "\nfruit(blueberry).")
            PrologStreams.close(stream)

            # Open stream in append mode
            stream = PrologStreams.open_stream(swipl, unixpath, :append, true, "TestStream `append`")
            PrologStreams.write(stream, "\nfruit(strawberry).")
            PrologStreams.close(stream)

            # Open stream in read mode, should throw error
            stream = PrologStreams.open_stream(swipl, unixpath, :read, true, "TestStream `read`")
            @test_throws ErrorException PrologStreams.write(stream, "\nfruit(strawberry).")
            PrologStreams.close(stream)

            Base.close(swipl)

            # Ensure the writes made it to the file
            @test occursin("fruit(blueberry).", read(path, String))
            @test occursin("fruit(strawberry).", read(path, String))

        end

    end

    @testset "save" begin
        mktemp() do path, io
            Base.close(io)
            unixpath = replace(path, "\\" => "/")

            # Open, write, and save a statement to the file
            swipl = SWIPL2J.start_swipl()
            stream = PrologStreams.open_stream(swipl, unixpath, :append, true, "TestStream save")
            PrologStreams.write(stream, "\nfruit(raspberry).")
            PrologStreams.save(stream)
            PrologStreams.close(stream)
            Base.close(swipl)

            # test the statement exists in the file
            @test occursin("fruit(raspberry).", read(path, String))
        end

    end

end