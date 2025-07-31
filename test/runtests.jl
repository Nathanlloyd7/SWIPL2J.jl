using Revise
using Test

if !isdefined(@__MODULE__, :SWIPL2J)
    using SWIPL2J
end

@testset "SWIPL2J" begin
    # Test the "open(`swipl`)" command to ensure Julia can launch SWI-Prolog.
    # This test uses only the built in functionality of Julia to check if SWI-Prolog can be launched.
    @testset "swipl" begin
        try
            swipl = open(`swipl -q`)
            close(swipl)
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
            @test false
        end

    end

    # Ensure start_swipl opens an SWI-Prolog process.
    @testset "start_swipl" begin
        try
            swipl = SWIPL2J.start_swipl("test.pl")
            @test isopen(swipl)
            close(swipl)
        catch e
            @test false
        end
    end

    # Ensure close_swipl closes the given SWI-Prolog process.
    @testset "close_swipl" begin
        try
            swipl = SWIPL2J.start_swipl("test.pl")
            SWIPL2J.close_swipl(swipl)
            @test !isopen(swipl)
        catch e
            @test false
        end

    end
    
end