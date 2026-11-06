@testset "parseTemporalResolution" begin
    @test parseTemporalResolution("day") == (1, "day")
    @test parseTemporalResolution("hour") == (1, "hour")
    @test parseTemporalResolution("") == (1, "")
    @test parseTemporalResolution("6-hour") == (6, "hour")
    @test parseTemporalResolution("1-day") == (1, "day")
    @test parseTemporalResolution("2-day") == (2, "day")
    @test parseTemporalResolution("3-month") == (3, "month")

    @test_throws ErrorException parseTemporalResolution("0-hour")
    @test_throws ErrorException parseTemporalResolution("-1-hour")
    @test_throws ErrorException parseTemporalResolution("abc-hour")
    @test_throws ErrorException parseTemporalResolution("6.5-hour")
    @test_throws ErrorException parseTemporalResolution("6-6-hour")
end

@testset "getUnitConversionForParameter" begin
    # regression: bare units unchanged
    @test getUnitConversionForParameter("day", "hour") == 1/24
    @test getUnitConversionForParameter("hour", "day") == 24
    @test getUnitConversionForParameter("day", "day") == 1
    @test getUnitConversionForParameter("month", "day") == 1/30
    @test getUnitConversionForParameter("year", "second") == 1/365 * 1/(60*60*24)

    # empty p_timescale (the common "not time-dependent" default) stays a no-op
    @test getUnitConversionForParameter("", "day") == 1
    @test getUnitConversionForParameter("", "6-hour") == 1

    # n-unit on model_timestep side
    @test getUnitConversionForParameter("day", "6-hour") == getUnitConversionForParameter("day", "hour") * 6
    @test getUnitConversionForParameter("day", "1-hour") == getUnitConversionForParameter("day", "hour")

    # n-unit on p_timescale side
    @test getUnitConversionForParameter("6-hour", "day") == getUnitConversionForParameter("hour", "day") / 6
    @test getUnitConversionForParameter("1-day", "day") == getUnitConversionForParameter("day", "day")

    # n-unit on both sides
    @test getUnitConversionForParameter("2-day", "6-hour") ≈ getUnitConversionForParameter("day", "hour") * 6 / 2

    # malformed strings propagate as errors
    @test_throws ErrorException getUnitConversionForParameter("day", "0-hour")
    @test_throws ErrorException getUnitConversionForParameter("day", "abc-hour")

    # unrecognized non-empty base units now error on both sides
    @test_throws ErrorException getUnitConversionForParameter("day", "fortnight")
    @test_throws ErrorException getUnitConversionForParameter("fortnight", "day")
end
