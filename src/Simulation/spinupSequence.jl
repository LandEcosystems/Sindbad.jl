export getSpinupSequence
export prepSequenceDefault
export prepSequenceWithAge


"""
    getSpinupSequence(method, spinup_config, loc_forcing, helpers_dates, aggregator_cache)

Build the spinup sequence of one location for the given sequence method.

# Arguments:
- `method`: a SINDBAD `SpinupSequence` that determines how the steps are chosen
- `spinup_config`: the spinup settings, with the sequence method and its `options`
- `loc_forcing`: a forcing NT for a single location, from which a method may read variables
- `helpers_dates`: a NT with date-related helpers of the experiment
- `aggregator_cache`: a Dict of already built temporal aggregators, shared across locations

# Returns:
- a tuple of `SpinupStepWithAggregator`, one per step of the sequence

# spinup sequence method:

    $(methods_of(SpinupSequence))

---

# Extended help

# Notes:
- The sequence is built here rather than while reading the settings because a method may need
  the forcing of a location, which only exists once the data is loaded.
- To add a method, define a type that subtypes `SpinupSequence` in `SimulationTypes.jl`
  and a `getSpinupSequence` method for it here. The method name in the settings is the type
  name in snake case, so `SequenceWithAge` is written as `sequence_with_age`.
"""
function getSpinupSequence end

function getSpinupSequence(::SequenceDefault, spinup_config, _, helpers_dates, aggregator_cache)
    options = spinup_config.options
    steps = prepSequenceDefault(; nrepeat_base=options.n_repeat_base, forcing_msc=options.forcing_msc)
    return Tuple(getSpinupSequenceWithTypes(steps, helpers_dates, aggregator_cache))
end

function getSpinupSequence(::SequenceList, spinup_config, _, helpers_dates, aggregator_cache)
    return Tuple(getSpinupSequenceWithTypes(spinup_config.options.steps, helpers_dates, aggregator_cache))
end

function getSpinupSequence(::SequenceWithAge, spinup_config, loc_forcing, helpers_dates, aggregator_cache)
    options = spinup_config.options
    year_disturbance = getproperty(loc_forcing, Symbol(options.disturbance_variable))
    steps = prepSequenceWithAge(Int(first(year_disturbance));
        nrepeat_base=options.n_repeat_base,
        year_start=year(first(helpers_dates.range)),
        forcing_msc=options.forcing_msc)
    return Tuple(getSpinupSequenceWithTypes(steps, helpers_dates, aggregator_cache))
end


"""
    prepSequenceDefault(; nrepeat_base=200, forcing_msc="day_MSC")

Build the steps of the default spinup sequence: the selected spinup models are run over the
mean seasonal cycle, bracketed on either side by a single run over all years.

# Arguments:
- `nrepeat_base`=200 [default]: the repeats of the mean seasonal cycle
- `forcing_msc`: the name of the mean seasonal cycle spinup forcing set
# Outputs
- a vector of spinup sequence steps, to be given types by `getSpinupSequenceWithTypes`
"""
function prepSequenceDefault(; nrepeat_base=200, forcing_msc="day_MSC")
    return [
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => forcing_msc, "n_repeat" => nrepeat_base),
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
    ]
end


"""
    nrepeat_age(year_disturbance; year_start = 1979)

# Arguments:
- `year_disturbance`: a year date, as an string
- `year_start`: 1979 [default] start year, as an integer
"""
function nrepeat_age(year_disturbance::Int; year_start = 1979)
    return year_start - year_disturbance
end

"""
    nrepeatYearsAge(year_disturbance; year_start = 1979)

# Arguments:
- `year_disturbance`: a year date, as an string
- `year_start`: 1979 [default] start year, as an integer
# Outputs
- year difference
"""
function nrepeatYearsAge(year_disturbance; year_start = 1979) # parse(Int, "1979")
    return year_disturbance !== 9999 ? nrepeat_age(year_disturbance; year_start) : -99999 # -99999 no disturbance
end


"""
    prepSequenceWithAge(year_disturbance; nrepeat_base=200, year_start=1979, forcing_msc="day_MSC")

Build the steps of a spinup sequence that replays the age of a location, i.e. the years between
its disturbance and the start of the experiment.

# Arguments:
- `year_disturbance`: the year in which the location was disturbed, as an integer
- `nrepeat_base`=200 [default]: the repeats of the mean seasonal cycle before the disturbance
- `year_start`: 1979 [default] start year of the experiment, as an integer
- `forcing_msc`: the name of the mean seasonal cycle spinup forcing set
# Outputs
- a vector of spinup sequence steps, to be given types by `getSpinupSequenceWithTypes`
"""
function prepSequenceWithAge(year_disturbance; nrepeat_base=200, year_start = 1979, forcing_msc = "day_MSC")
    nrepeat_age = nrepeatYearsAge(year_disturbance; year_start)
    sequence = [
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => forcing_msc, "n_repeat" => nrepeat_base),
        Dict("spinup_mode" => "eta_scale_H", "forcing" => forcing_msc, "n_repeat" => 1),
    ]
    if nrepeat_age >= 0
        sequence = [
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => forcing_msc, "n_repeat" => nrepeat_base),
            Dict("spinup_mode" => "eta_scale_A0H", "forcing" => forcing_msc, "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => forcing_msc, "n_repeat" => nrepeat_age),
        ]
    end
    return sequence
end
