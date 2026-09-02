export coreTEM
export runTEM

"""
    coreTEM(selected_models, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_land, tem_info, spinup_mode)

Runs the SINDBAD Terrestrial Ecosystem Model (TEM) for a single location, with or without spinup, based on the specified `spinup_mode`.

# Arguments:
- `selected_models`: A tuple of all models selected in the given model structure.
- `loc_forcing`: A forcing NamedTuple containing the time series of environmental drivers for a single location.
- `loc_spinup_forcing`: A forcing NamedTuple for spinup, used to initialize the model to a steady state (only used if spinup is enabled).
- `loc_forcing_t`: A forcing NamedTuple for a single location and a single time step.
- `loc_land`: Initial SINDBAD land NamedTuple with all fields and subfields.
- `tem_info`: A helper NamedTuple containing necessary objects for model execution and type consistencies.
- `spinup_mode`: A type that determines whether spinup is included or excluded

# Returns:
- `land_time_series`: A vector of SINDBAD land states for each time step after the model simulation.
"""
function coreTEM end

function coreTEM(selected_models, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_land, tem_info, spinup_mode)

    land_prec = precomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers)

    land_spin = spinupTEM(selected_models, loc_spinup_forcing, loc_forcing_t, land_prec, tem_info, spinup_mode)

    land_time_series = timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_spin, tem_info, tem_info.run.debug_model)
    return land_time_series
end


function coreTEM(selected_models, loc_forcing, loc_spinup_forcing, loc_forcing_t, land_time_series, loc_land, tem_info, spinup_mode)
    land_prec = precomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers)

    land_spin = spinupTEM(selected_models, loc_spinup_forcing, loc_forcing_t, land_prec, tem_info, spinup_mode)

    timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_time_series, land_spin, tem_info, tem_info.run.debug_model)
    return nothing
end

"""
    runTEM(forcing::NamedTuple, info::NamedTuple)
    runTEM(selected_models::Tuple, forcing::NamedTuple, loc_spinup_forcing, loc_forcing_t, loc_land::NamedTuple, tem_info::NamedTuple)
    runTEM(selected_models::Tuple, loc_forcing::NamedTuple, loc_spinup_forcing, loc_forcing_t, land_time_series, loc_land::NamedTuple, tem_info::NamedTuple)

Runs the SINDBAD Terrestrial Ecosystem Model (TEM) for a single location, with or without spinup, based on the provided configurations. The two main variants are the ones with and without the preallocated land time series. The shorthand version with two input arguments calls the one without preallocated land time series.

# Arguments:
- `selected_models`: A tuple of all models selected in the given model structure.
- `forcing::NamedTuple`: A forcing NamedTuple containing the time series of environmental drivers for all locations.
- `loc_spinup_forcing`: A forcing NamedTuple for spinup, used to initialize the model to a steady state.
- `loc_forcing_t`: A forcing NamedTuple for a single location and a single time step.
- `loc_land::NamedTuple`: Initial SINDBAD land NamedTuple with all fields and subfields.
- `tem_info::NamedTuple`: A nested NamedTuple containing necessary information, including:
    - Model helpers.
    - Spinup configurations.
    - Debugging options.
    - Output configurations.

# Returns:
- `LandWrapper`: A wrapper containing the time series of SINDBAD land states for each time step after the model simulation.

# Notes:
- The function internally calls `coreTEM` to handle the main simulation logic.
- If spinup is enabled (`DoSpinupTEM`), the function runs the spinup process before the main simulation.
- If spinup is disabled (`DoNotSpinupTEM`), the function directly runs the main simulation.
- The function prepares the necessary inputs and configurations using `prepTEM` before executing the simulation.

# Examples
```jldoctest
julia> using Sindbad

julia> # Run TEM with spinup (shorthand version)
julia> # land_time_series = runTEM(forcing, info)

julia> # Run TEM with spinup (detailed version)
julia> # land_time_series = runTEM(selected_models, forcing, loc_spinup_forcing, loc_forcing_t, loc_land, tem_info)

julia> # Run TEM without spinup
julia> # land_time_series = runTEM(selected_models, forcing, nothing, loc_forcing_t, loc_land, tem_info)
```
"""
function runTEM end

function runTEM(forcing::NamedTuple, info::NamedTuple)
    run_helpers = prepTEM(forcing, info)
    land_time_series = coreTEM(info.models.forward, run_helpers.space_forcing[1], run_helpers.space_spinup_forcing[1], run_helpers.loc_forcing_t, run_helpers.loc_land, run_helpers.tem_info, run_helpers.tem_info.run.spinup_TEM)
    return LandWrapper(land_time_series)
end


function runTEM(selected_models::Tuple, forcing::NamedTuple, loc_spinup_forcing, loc_forcing_t, loc_land::NamedTuple, tem_info::NamedTuple)
    land_time_series = coreTEM(selected_models, forcing, loc_spinup_forcing, loc_forcing_t, loc_land, tem_info, tem_info.run.spinup_TEM)
    return LandWrapper(land_time_series)
end

function runTEM(selected_models::Tuple, loc_forcing::NamedTuple, loc_spinup_forcing, loc_forcing_t, land_time_series, loc_land::NamedTuple, tem_info::NamedTuple)
    coreTEM(selected_models, loc_forcing, loc_spinup_forcing, loc_forcing_t, land_time_series, loc_land, tem_info, tem_info.run.spinup_TEM)
    return LandWrapper(land_time_series)
end


"""
    timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_time_series, land, tem_info, debug_mode)
    timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land, tem_info, debug_mode)

Executes the time loop for the SINDBAD Terrestrial Ecosystem Model (TEM), running the model for each time step using the provided forcing data and updating the land. There are two major variants with and without the preallocated land time series. In the debug mode only 1 time step is executed for debugging the allocations in each model.

# Arguments:
- `selected_models`: A tuple of all models selected in the given model structure.
- `loc_forcing`: A forcing NamedTuple containing the time series of environmental drivers for all locations.
- `loc_forcing_t`: A forcing NamedTuple for a single location and a single time step.
- `land_time_series`: A preallocated vector (length = number of time steps) to store SINDBAD land states for each time step.
- `land`: A SINDBAD NamedTuple containing all variables for a given time step, which is overwritten at every time step.
- `tem_info`: A helper NamedTuple containing necessary objects for model execution and type consistencies.
- `debug_mode`: A type dispatch that determines whether debugging is enabled or disabled:
    - `DoDebugModel`: Runs the model for a single time step and displays debugging information (e.g., allocations, execution time). Set`debug_model` to `true` in flag section of experiment_json.
    - `DoNotDebugModel`: Runs the model for all time steps without debugging. Set`debug_model` to `false` in flag section of experiment_json.

# Returns:
- `nothing`: The function modifies `land_time_series` in place to store the results for each time step.

# Notes:
- For each time step:
    - The function retrieves the forcing data for the current time step using `getForcingForTimeStep`.
    - The model is executed using `computeTEM`, which updates the land state.
    - The updated land state is stored in `land_time_series`.
- When `DoDebugModel` is used:
    - The function runs the model for a single time step and logs debugging information, such as execution time and memory allocations.
- When `DoNotDebugModel` is used:
    - The function runs the model for all time steps in a loop.

# Examples:
1. **Running the time loop without debugging**:
```julia
timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_time_series, land, tem_info, DoNotDebugModel())
```

2. **Running the time loop with debugging**:
```julia
timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_time_series, land, tem_info, DoDebugModel())
```
"""
function timeLoopTEM end

function timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_time_series, land, tem_info, ::DoNotDebugModel) # do not debug the models
    for ts ∈ 1:tem_info.n_timesteps
        f_ts = getForcingForTimeStep(loc_forcing, loc_forcing_t, ts, tem_info.vals.forcing_types)
        land = computeTEM(selected_models, f_ts, land, tem_info.model_helpers)
        land_time_series[ts] = land
    end
    return nothing
end

function timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land, _, tem_info, ::DoDebugModel) # debug the models
    timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land, tem_info, DoDebugModel())
    return nothing
end

function timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land, tem_info, ::DoNotDebugModel) # do not debug the models
    land_time_series = map(1:tem_info.n_timesteps) do ts
        f_ts = getForcingForTimeStep(loc_forcing, loc_forcing_t, ts, tem_info.vals.forcing_types)
        land = computeTEM(selected_models, f_ts, land, tem_info.model_helpers)
        land
    end
    return land_time_series
end

function timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land, tem_info, ::DoDebugModel) # debug the models
    print_info(nothing, @__FILE__, @__LINE__, "\n`----------------------------------------forcing--------------------------------------------------------------`\n", display_color=(214,39,82))
    @time f_ts = getForcingForTimeStep(loc_forcing, loc_forcing_t, 1, tem_info.vals.forcing_types)
    print_info(nothing, @__FILE__, @__LINE__, "\n`----------------------------------------each model--------------------------------------------------------------`\n", display_color=(214,39,82))
    @time land = computeTEM(selected_models, f_ts, land, tem_info.model_helpers, tem_info.run.debug_model)
    print_info(nothing, @__FILE__, @__LINE__, "\n`----------------------------------------all models--------------------------------------------------------------`\n", display_color=(214,39,82))
    @time land = computeTEM(selected_models, f_ts, land, tem_info.model_helpers)
    print_info_separator()
    return [land]
end
