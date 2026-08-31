export getSequence
export setSequence

"""
    nrepeat_age(year_disturbance; year_start = 1979)

# Arguments:
- `year_disturbance`: a year date, as an string
- `year_start`: 1979 [default] start year, as an integer
"""
function nrepeat_age(year_disturbance; year_start = 1979)
    return year_start - year(Date(year_disturbance))
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
    return year_disturbance !== "undisturbed" ? nrepeat_age(year_disturbance; year_start) : -99999 # -99999 no disturbance
end


"""
    getSequence(year_disturbance, nrepeat_base=200, year_start = 1979)

# Arguments:
- `year_disturbance`: a year date, as an string
- `nrepeat_base`=200 [default]
- `year_start`: 1979 [default] start year, as an interger
# Outputs
- new spinup sequence object
"""
function getSequence(year_disturbance, info_helpers_dates; nrepeat_base=200, year_start = 1979)
    nrepeat_age = nrepeatYearsAge(year_disturbance; year_start)
    sequence = [
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat_base),
        Dict("spinup_mode" => "eta_scale_AH", "forcing" => "day_MSC", "n_repeat" => 1),
    ]
    if nrepeat_age == 0
        sequence = [
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat_base),
            Dict("spinup_mode" => "eta_scale_A0H", "forcing" => "day_MSC", "n_repeat" => 1),
        ]
    elseif nrepeat_age > 0
        sequence = [
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat_base),
            Dict("spinup_mode" => "eta_scale_A0H", "forcing" => "day_MSC", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat_age),
        ]
    end
    # keep the sequence as a tuple of SpinupSequenceWithAggregator, which is what
    # getAllSpinupForcing and the spinup loop dispatch on
    new_sequence = Tuple(getSpinupSequenceWithTypes(sequence, info_helpers_dates))
    return new_sequence
end

"""
    setSequence(tem_info, new_sequence)

# Arguments:
- `tem_info`: Tuple with the field `spinup_sequence`
- `new_sequence`
# Outputs
- an updated tem_info object with new spinup sequence modes
"""
function setSequence(tem_info, new_sequence)
    return @set tem_info.spinup_sequence = new_sequence
end