include(joinpath(@__DIR__, "..", "..", "tools", "benchmark", "TestSindbadTEM", "scanApproachVariables.jl"))

@testset "isValidTimescale" begin
    @test isValidTimescale("")
    @test isValidTimescale("day")
    @test isValidTimescale("second")
    @test isValidTimescale("minute")
    @test isValidTimescale("hour")
    @test isValidTimescale("month")
    @test isValidTimescale("year")
    @test isValidTimescale("8-day")
    @test isValidTimescale("6-hour")
    @test isValidTimescale("1-year")

    @test !isValidTimescale("week")
    @test !isValidTimescale("decade")
    @test !isValidTimescale("halfhour")
    @test !isValidTimescale("fortnight")
    @test !isValidTimescale("Day")
    @test !isValidTimescale("days")

    @test_throws ErrorException isValidTimescale("0-day")
    @test_throws ErrorException isValidTimescale("abc-day")
end

@testset "Parameter timescales are within the allowed set" begin
    bad = Tuple{Symbol,Symbol,String}[]  # (approach, field, timescale)
    for T in leafSubtypes(LandEcosystem)
        model = T()
        for fn in fieldnames(T)
            ts = SindbadTEM.Processes.timescale(model, fn)
            isValidTimescale(ts) || push!(bad, (nameof(T), fn, ts))
        end
    end
    if !isempty(bad)
        @error "Approaches with an unsupported parameter timescale" bad
    end
    @test isempty(bad)
end
