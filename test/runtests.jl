using Revise
using Test

if !isdefined(@__MODULE__, :SWIPL2J)
    using SWIPL2J
end

@testset "SWIPL2J.jl" begin
    # Write your tests here.

    # Test the "open(`swipl`)" command to ensure Julia can launch SWIPL.
    # This test uses only the built in functionality of Julia to check if SWIPL can be launched.
    @testset "swipl" begin
        try
            swipl = open(`swipl -q`)
            close(swipl)
            @test true
        catch e
            @test false
        end
    end

    # Dont know if you want this test or not
    # Test the echo_term function for any errors.
    @testset "echo_term" begin
        try
            SWIPL2J.echo_term()
            @test true
        catch e
            @test false
        end

    end

    # Test the start_swipl function for any errors, ensure it opens a SWIPL process.
    @testset "start_swipl" begin
        try
            swipl = SWIPL2J.start_swipl("test\\test.pl")
            @test isopen(swipl)
            close(swipl)
        catch e
            @test false
        end
    end

    # Test the close_swipl function for any errors, ensure it closes the given SWIPL process.
    @testset "close_swipl" begin
        try
            swipl = SWIPL2J.start_swipl("test\\test.pl")
            SWIPL2J.close_swipl(swipl)
            @test !isopen(swipl)
        catch e
            @test false
        end

    end
    
end