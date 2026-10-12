using Dates
using Statistics
using Sindbad.Setup: getCostTimeResampler, getSpinupAggregator, getSpinupSequenceWithTypes

# minimal stand in for info.temp.helpers.dates
function mockDatesHelpers(date_begin, date_end, temporal_resolution)
    timestep = get_time_period(temporal_resolution)
    range = DateTime(date_begin):timestep:DateTime(date_end)
    return (; range=range, timestep=timestep, temporal_resolution=temporal_resolution)
end

@testset "cost time resampler" begin
    daily = mockDatesHelpers("2001-01-01", "2003-12-31", "day")
    hourly = mockDatesHelpers("2001-01-01", "2001-03-31T23:00", "hour")
    x_daily = rand(length(daily.range), 2)
    x_hourly = rand(length(hourly.range), 2)

    # the model resolution skips the first sampler and uses the data as it is
    rs = getCostTimeResampler("day", daily, mean)
    @test first(rs.samplers) === nothing
    @test time_resample(x_daily, rs) === x_daily
    rs = getCostTimeResampler("hour_anomaly", hourly, mean)
    @test first(rs.samplers) === nothing
    @test rs.combine == TimeDiff()
    @test time_resample(x_hourly, rs) ≈ x_hourly .- mean(x_hourly; dims=1)

    # existing names give the same values as the old sampler and combine type pair
    for (name, method, combine) in (("month", TimeMonth(), TimeNoDiff()),
                                    ("month_anomaly", TimeMonthAnomaly(), TimeDiff()),
                                    ("day_MSC", TimeDayMSC(), TimeNoDiff()),
                                    ("day_iav", TimeDayIAV(), TimeDiff()))
        old = do_time_sampling(x_daily, create_TimeSampler(daily.range, method, mean), combine)
        rs = getCostTimeResampler(name, daily, mean)
        @test rs.combine == combine
        @test time_resample(x_daily, rs) ≈ old
    end

    # period specs get the combine step of their method
    @test getCostTimeResampler("8-day_msc", daily, mean).combine == TimeNoDiff()
    @test getCostTimeResampler("8-day_iav", daily, mean).combine == TimeDiff()
    @test getCostTimeResampler("3h_anomaly", hourly, mean).combine == TimeDiff()
    @test getCostTimeResampler("30-min_iav_day", mockDatesHelpers("2001-01-01", "2001-01-10", "30-min"), mean).combine == TimeDiff()
    @test size(time_resample(x_daily, getCostTimeResampler("8-day_msc", daily, mean))) == (46, 2)

    # the skip only applies when the bins have the length of the model timestep
    @test first(getCostTimeResampler("3-hour", hourly, mean).samplers) !== nothing
    @test first(getCostTimeResampler("1-hour", hourly, mean).samplers) === nothing
    @test first(getCostTimeResampler("h", hourly, mean).samplers) === nothing

    # the aggregation function is used for every group
    rs_sum = getCostTimeResampler("month", daily, sum)
    @test time_resample(x_daily, rs_sum)[1, :] ≈ vec(sum(x_daily[1:31, :]; dims=1))
end

@testset "spinup aggregator" begin
    daily = mockDatesHelpers("2001-01-01", "2002-12-31", "day")
    hourly = mockDatesHelpers("2001-01-01", "2001-12-31T23:00", "hour")

    aggregator, indices, n_timesteps, aggregator_type = getSpinupAggregator("day_MSC", daily, Dict{Symbol,Any}())
    @test aggregator isa TimeResampler
    @test aggregator_type == TimeNoDiff()
    @test n_timesteps == 365

    aggregator, indices, n_timesteps, aggregator_type = getSpinupAggregator("first_year", daily, Dict{Symbol,Any}())
    @test aggregator === nothing
    @test aggregator_type == TimeIndexed()
    @test indices == collect(1:365)
    @test n_timesteps == 365

    _, indices, n_timesteps, aggregator_type = getSpinupAggregator("all_years", daily, Dict{Symbol,Any}())
    @test aggregator_type == TimeIndexed()
    @test n_timesteps == length(daily.range)

    # a forcing at the model resolution used to fail on a skipped sampler
    _, _, n_timesteps, _ = getSpinupAggregator("day", daily, Dict{Symbol,Any}())
    @test n_timesteps == length(daily.range)

    # period specs, and a forcing coarser than the model timestep
    _, _, n_timesteps, _ = getSpinupAggregator("8-day_msc", daily, Dict{Symbol,Any}())
    @test n_timesteps == 46
    _, _, n_timesteps, _ = getSpinupAggregator("day_MSC", hourly, Dict{Symbol,Any}())
    @test n_timesteps == 365

    @test_throws ErrorException getSpinupAggregator("day_anomaly", daily, Dict{Symbol,Any}())

    # the aggregator is built once per forcing name
    cache = Dict{Symbol,Any}()
    @test getSpinupAggregator("day_MSC", daily, cache) === getSpinupAggregator("day_MSC", daily, cache)
end

@testset "spinup sequence" begin
    daily = mockDatesHelpers("2001-01-01", "2002-12-31", "day")
    steps = [Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
             Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => 2)]
    sequence = getSpinupSequenceWithTypes(steps, daily)
    @test sequence[1].aggregator === nothing
    @test sequence[1].aggregator_type == TimeIndexed()
    @test sequence[1].n_timesteps == length(daily.range)
    @test sequence[2].aggregator isa TimeResampler
    @test sequence[2].aggregator_type == TimeNoDiff()
    @test sequence[2].n_timesteps == 365
    @test sequence[2].n_repeat == 2
end
