export getSpatialInfo
export prepTEM


"""
    addErrorCatcher(loc_land, debug_mode)

Adds an error catcher to monitor and debug the SINDBAD land variables during model execution.

# Arguments:
- `loc_land`: A core SINDBAD NamedTuple containing all variables for a given time step, which is overwritten at every time step.
- `debug_mode`: A type dispatch to determine whether debugging is enabled:
    - `DoDebugModel`: Enables debugging and adds `loc_land` to the error catcher. Set `debug_model` to true in flag section of experiment_json.
    - `DoNotDebugModel`: Disables debugging and does nothing. Set `debug_model` to false in flag section of experiment_json.

# Returns:
- `nothing`: The function modifies global state or performs debugging actions but does not return a value.

# Notes:
- When `debug_mode` is `DoDebugModel`, the function:
    - Initializes an error catcher if it does not already exist. This error_catcher is a global variable where you can add any variable from within SINDBAD while debugging, and this variable will be available during an experiment run REPL session.
    - Pushes the current `loc_land` to the error catcher for debugging purposes.
    - Prints the `loc_land` for inspection using `tc_print`.
- When `debug_mode` is `DoNotDebugModel`, the function performs no actions.

# Examples
```jldoctest
julia> using Sindbad

julia> # Enable debugging mode
julia> # loc_land = (temperature = 15.0, precipitation = 100.0)
julia> # addErrorCatcher(loc_land, DoDebugModel())

julia> # Disable debugging mode
julia> # addErrorCatcher(loc_land, DoNotDebugModel())
```
"""
function addErrorCatcher end


function addErrorCatcher(loc_land, ::DoDebugModel) # print land when debug model is true/on
    SindbadTEM.eval(:(error_catcher = []))
    push!(SindbadTEM.error_catcher, loc_land)
    tc_print(loc_land)
    return nothing
end

function addErrorCatcher(_, ::DoNotDebugModel) # do nothing debug model is false/off
    return nothing
end

"""
    addSpinupLog(loc_land, sequence, ::SpinupLogType)

Adds or skips the preallocated holder for storing the spinup log during model spinup, depending on the specified `SpinupLogType`.

# Arguments:
- `loc_land`: A core SINDBAD NamedTuple containing all variables for a given time step, which is overwritten at every time step.
- `sequence`: The spinup sequence, which defines the number of repeats and timesteps for the spinup process.
- `::SpinupLogType`: A type dispatch that determines whether to store the spinup log:
    - `DoStoreSpinup`: Enables storing the spinup log for each repeat of the spinup process. Set `store_spinup` to true in flag section of experiment_json.
    - `DoNotStoreSpinup`: Skips storing the spinup log. Set `store_spinup` to false in flag section of experiment_json.

# Returns:
- `loc_land`: The updated `loc_land` NamedTuple, potentially with the spinup log added.

# Notes:
- When `DoStoreSpinup` is used:
    - The function calculates the total number of repeats in the spinup sequence.
    - Preallocates a vector to store the spinup log for each repeat.
    - Updates the `loc_land` NamedTuple with the spinup log.
- When `DoNotStoreSpinup` is used, the function simply returns `loc_land` without modifications.

# Examples:
1. **Storing the spinup log**:
```julia
loc_land = (pools = rand(10), states = rand(10))
sequence = [(n_repeat = 3, n_timesteps = 10), (n_repeat = 2, n_timesteps = 5)]
loc_land = addSpinupLog(loc_land, sequence, DoStoreSpinup())
```

2. **Skipping the spinup log**:
```julia
loc_land = (pools = rand(10), states = rand(10))
sequence = [(n_repeat = 3, n_timesteps = 10), (n_repeat = 2, n_timesteps = 5)]
loc_land = addSpinupLog(loc_land, sequence, DoNotStoreSpinup())
```
"""
function addSpinupLog end

function addSpinupLog(loc_land, sequence, ::DoStoreSpinup) # when history is true
    n_repeat = 1
    for _seq in sequence
        n_repeat = n_repeat + _seq.n_repeat
    end
    spinuplog = Vector{typeof(loc_land.pools)}(undef, n_repeat)
    @pack_nt spinuplog ⇒ loc_land.states
    return loc_land
end

function addSpinupLog(loc_land, _, ::DoNotStoreSpinup) # when history is false
    return loc_land
end


"""
    filterNanPixels(forcing, loc_space_maps, filter_nan_pixels_mode)

Filters out spatial pixels where all timesteps contain NaN values, based on the specified filtering mode.

# Arguments:
- `forcing`: A forcing NamedTuple containing the time series of environmental drivers for all locations.
- `loc_space_maps`: A collection of local spatial coordinates for all input points.
- `filter_nan_pixels_mode`: A type dispatch that determines whether to filter NaN-only pixels:
    - `DoFilterNanPixels`: Filters out pixels where all timesteps are NaN. Set `filter_nan_pixels` to true in flag section of experiment_json.
    - `DoNotFilterNanPixels`: Does not filter any pixels, returning the input `loc_space_maps` unchanged. Set `filter_nan_pixels` to false in flag section of experiment_json.

# Returns:
- `loc_space_maps`: The filtered or unfiltered spatial coordinates, depending on the filtering mode.

# Notes:
- When `DoFilterNanPixels` is used:
    - The function iterates through all spatial locations and checks if all timesteps for a given location are NaN. NOTE THAT THIS WILL BE SLOW FOR LARGE DATASETS AS ALL LAZILY-LOADED DATA ARE STORED IN MEMORY.
    - Locations with all NaN values are excluded from the returned `loc_space_maps`.
- When `DoNotFilterNanPixels` is used, the function simply returns the input `loc_space_maps` without any modifications.

# Examples:
1. **Filtering NaN-only pixels**:
```julia
forcing = (data = ..., variables = ...)
loc_space_maps = [(1, 2), (3, 4), (5, 6)]
filtered_maps = filterNanPixels(forcing, loc_space_maps, DoFilterNanPixels())
```

2. **Skipping NaN filtering**:
```julia
forcing = (data = ..., variables = ...)
loc_space_maps = [(1, 2), (3, 4), (5, 6)]
filtered_maps = filterNanPixels(forcing, loc_space_maps, DoNotFilterNanPixels())
```
"""
function filterNanPixels end

function filterNanPixels(_, loc_space_maps, ::DoNotFilterNanPixels)
    return loc_space_maps
end


function filterNanPixels(forcing, loc_space_maps, ::DoFilterNanPixels)
    forcing_nt_array = namedtuple_from_names_values(forcing.data, forcing.variables)
    allNans = Bool[]
    for i ∈ eachindex(loc_space_maps)
        loc_ind = Tuple(last.(loc_space_maps[i]))
        loc_forcing = getLocData(forcing_nt_array, loc_ind)
        push!(allNans, all(isnan, loc_forcing[1]))
    end
    loc_space_maps = loc_space_maps[allNans.==false]
    return loc_space_maps
end


"""
    getRunTEMInfo(info, forcing)

a helper to condense the useful info only for the inner model runs

# Arguments:
- `info`: a nested NT with necessary information of helpers, models, and spinup needed to run SINDBAD TEM and models
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
"""
function getRunTEMInfo(info, forcing)
    tem_helpers=info.helpers
    output_vars = info.output.variables
    @debug "     preparing vals for generated functions"
    vals = (; forcing_types=Val(forcing.f_types), output_vars=Val(output_vars))
    upd_tem_helpers = (;)
    tem_dates = tem_helpers.dates
    tem_dates = (;)
    # upd_tem_helpers = set_namedtuple_field(upd_tem_helpers, (:dates, tem_dates))
    time_size = getproperty(forcing.helpers.sizes, Symbol(forcing.helpers.dimensions.time))
    upd_tem_helpers = set_namedtuple_field(upd_tem_helpers, (:n_timesteps, time_size))
    tem_numbers = tem_helpers.numbers
    tem_numbers = (; tolerance=tem_numbers.tolerance)
    model_helpers = (;)
    model_helpers = set_namedtuple_field(model_helpers, (:dates, tem_dates))
    model_helpers = set_namedtuple_field(model_helpers, (:run, (; catch_model_errors=tem_helpers.run.catch_model_errors)))
    model_helpers = set_namedtuple_field(model_helpers, (:numbers, tem_numbers))
    model_helpers = set_namedtuple_field(model_helpers, (:pools, tem_helpers.pools))
    upd_tem_helpers = set_namedtuple_field(upd_tem_helpers, (:vals, vals))
    upd_tem_helpers = set_namedtuple_field(upd_tem_helpers, (:model_helpers, model_helpers))
    upd_tem_helpers = set_namedtuple_field(upd_tem_helpers, (:run, tem_helpers.run))
    # upd_tem_helpers = set_namedtuple_field(upd_tem_helpers, (:spinup_sequence, getSpinupTemLite(info.spinup.sequence)))
    # don't do `getSpinupTemLite` here, but rather later on more inner functions! 
    # ! BECAUSE THIS IS LOADING ALL THE DATA
    upd_tem_helpers = set_namedtuple_field(upd_tem_helpers, (:spinup_sequence, info.spinup.sequence))

    return upd_tem_helpers
end


"""
    getSpatialInfo(forcing_helpers)
    getSpatialInfo(forcing, filterNanPixels)

get the information of the indices of the data to run the model for. The second variant additionally filter pixels with all nan data

# Arguments:
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
"""
function getSpatialInfo end

function getSpatialInfo(forcing_helpers)
    @debug "     getting the space locations to run the model loop"
    forcing_sizes = forcing_helpers.sizes
    loopvars = collect(keys(forcing_sizes))
    additionaldims = setdiff(loopvars, [Symbol(forcing_helpers.dimensions.time)])
    spacesize = values(forcing_sizes[additionaldims])
    loc_space_maps = vec(collect(Iterators.product(Base.OneTo.(spacesize)...)))
    loc_space_maps = map(loc_space_maps) do loc_names
        map(zip(loc_names, additionaldims)) do (loc_index, lv)
            lv => loc_index
        end
    end
    loc_space_maps = Tuple(loc_space_maps)
    space_ind = Tuple([Tuple(last.(loc_space_map)) for loc_space_map ∈ loc_space_maps])
    return space_ind, loc_space_maps
end

function getSpatialInfo(forcing, filter_nan_pixels)
    space_ind, loc_space_maps = getSpatialInfo(forcing.helpers)
    loc_space_maps = filterNanPixels(forcing, loc_space_maps, filter_nan_pixels)
    space_ind = Tuple([Tuple(last.(loc_space_map)) for loc_space_map ∈ loc_space_maps])
    return space_ind
end



"""
    getSpinupTemLite(tem_spinup)

a helper to just get the spinup sequence to pass to inner functions

# Arguments:
- `tem_spinup_sequence`: a NT with all spinup information
"""
function getSpinupTemLite(tem_spinup_sequence)
    newseqs = []
    for seq in tem_spinup_sequence
        ns = (; forcing=seq.forcing, n_repeat= seq.n_repeat, n_timesteps=seq.n_timesteps, spinup_mode=seq.spinup_mode, options=seq.options)
        push!(newseqs, ns)
    end
    sequence = [_s for _s in newseqs]
    return sequence

end

"""
    helpPrepTEM(selected_models, info, forcing::NamedTuple, output::NamedTuple, ::PreAlloc)

Prepares the necessary information and objects needed to run the SINDBAD Terrestrial Ecosystem Model (TEM).

# Arguments:
- `selected_models`: A tuple of all models selected in the given model structure.
- `info`: A nested NamedTuple containing necessary information, including:
    - Helpers for running the model.
    - Model configurations.
    - Spinup settings.
- `forcing::NamedTuple`: A forcing NamedTuple containing the time series of environmental drivers for all locations.
- `output::NamedTuple`: An output NamedTuple containing data arrays, variable information, and dimensions.
- `::PreAllocputType`: A type dispatch that determines the output preparation strategy.

# Returns:
- A NamedTuple (`run_helpers`) containing preallocated data and configurations required to run the TEM, including:
    - Spatial forcing data.
    - Spinup forcing data.
    - Output arrays.
    - Land variables.
    - Temporal and spatial indices.
    - Model and helper configurations.

    
# sindbad land output type:
   
    $(methods_of(PreAlloc))

---

# Extended help

# Notes:
- The function dynamically prepares the required data structures based on the specified `PreAllocputType`.
- It handles spatial and temporal data preparation, including filtering NaN pixels, initializing land variables, and setting up forcing and output arrays.
- This function is a key step in preparing the SINDBAD TEM for execution.

# Examples
```jldoctest
julia> using Sindbad

julia> # Prepare TEM with PreAllocArray
julia> # run_helpers = helpPrepTEM(selected_models, info, forcing, output, PreAllocArray())

julia> # Prepare TEM with PreAllocTimeseries
julia> # run_helpers = helpPrepTEM(selected_models, info, forcing, output, PreAllocTimeseries())
```
```julia
run_helpers = helpPrepTEM(selected_models, info, forcing, observations, output, PreAllocArrayFD())
```
"""
function helpPrepTEM end

function helpPrepTEM(selected_models, info, forcing::NamedTuple, output::NamedTuple, ::PreAllocArray)

    print_info(helpPrepTEM, @__FILE__, @__LINE__, "preparing spatial and tem helpers", n_f=6)
    space_ind = getSpatialInfo(forcing, info.helpers.run.filter_nan_pixels)

    # generate vals for dispatch of forcing and output
    tem_info = getRunTEMInfo(info, forcing);


    ## run the model for one time step
    print_info(helpPrepTEM, @__FILE__, @__LINE__, "model run for one location and time step", n_f=6)
    forcing_nt_array = namedtuple_from_names_values(forcing.data, forcing.variables)
    land_init = output.land_init
    loc_forcing = getLocData(forcing_nt_array, space_ind[1])
    loc_forcing_t, loc_land = runTEMOne(selected_models, loc_forcing, land_init, tem_info)

    addErrorCatcher(loc_land, info.helpers.run.debug_model)

    output_array = output.data
    output_vars = output.variables
    output_dims = output.dims

    # collect local data and create copies
    print_info(helpPrepTEM, @__FILE__, @__LINE__, "preallocating local, threaded, and spatial data", n_f=6)
    space_forcing = map([space_ind...]) do lsi
        getLocData(forcing_nt_array, lsi)
    end
    space_spinup_forcing = map(space_forcing) do loc_forcing
        getAllSpinupForcing(loc_forcing, info.spinup.sequence, tem_info);
    end

    space_output = map([space_ind...]) do lsi
        getLocData(output_array, lsi)
    end

    space_land = Tuple([deepcopy(loc_land) for _ ∈ 1:length(space_ind)])

    space_selected_models = [[selected_models for _ ∈ 1:length(space_ind)]...]

    forcing_nt_array = nothing

    run_helpers = (; space_selected_models, space_forcing, space_ind, space_spinup_forcing, loc_forcing_t, output_array, space_output, space_land, loc_land, output_dims, output_vars, tem_info)
    return run_helpers
end

function helpPrepTEM(selected_models, info, forcing::NamedTuple, output::NamedTuple, ::PreAllocArrayAll)

    print_info(helpPrepTEM, @__FILE__, @__LINE__, "preparing spatial and tem helpers", n_f=6)
    space_ind = getSpatialInfo(forcing, info.helpers.run.filter_nan_pixels)

    # generate vals for dispatch of forcing and output
    tem_info = getRunTEMInfo(info, forcing);

    ## run the model for one time step
    print_info(helpPrepTEM, @__FILE__, @__LINE__, "model run for one location and time step", n_f=6)
    forcing_nt_array = namedtuple_from_names_values(forcing.data, forcing.variables)
    land_init = output.land_init
    loc_forcing = getLocData(forcing_nt_array, space_ind[1])
    loc_forcing_t, loc_land = runTEMOne(selected_models, loc_forcing, land_init, tem_info)

    addErrorCatcher(loc_land, info.helpers.run.debug_model)

    info = setModelOutputLandAll(info, loc_land)
    tem_info = @set tem_info.vals.output_vars = Val(info.output.variables)
    output_dims, output_array = getOutDimsArrays(info, forcing.helpers)

    # collect local data and create copies
    print_info(helpPrepTEM, @__FILE__, @__LINE__, "preallocating local, threaded, and spatial data", n_f=6)
    space_forcing = map([space_ind...]) do lsi
        getLocData(forcing_nt_array, lsi)
    end
    space_spinup_forcing = map(space_forcing) do loc_forcing
        getAllSpinupForcing(loc_forcing, info.spinup.sequence, tem_info);
    end

    space_output = map([space_ind...]) do lsi
        getLocData(output_array, lsi)
    end

    space_land = Tuple([deepcopy(loc_land) for _ ∈ 1:length(space_ind)])

    space_selected_models = [[selected_models for _ ∈ 1:length(space_ind)]...]

    forcing_nt_array = nothing

    run_helpers = (; space_selected_models, space_forcing, space_ind, space_spinup_forcing, loc_forcing_t, output_array, space_output, space_land, loc_land, output_dims, output_vars=info.output.variables, tem_info)
    return run_helpers
end



function helpPrepTEM(selected_models, info, forcing::NamedTuple, output::NamedTuple, ::PreAllocArrayFD)

    print_info(helpPrepTEM, @__FILE__, @__LINE__, "preparing spatial and tem helpers", n_f=6)
    space_ind = getSpatialInfo(forcing, info.helpers.run.filter_nan_pixels)

    # generate vals for dispatch of forcing and output
    tem_info = getRunTEMInfo(info, forcing);


    ## run the model for one time step
    print_info(helpPrepTEM, @__FILE__, @__LINE__, "model run for one location and time step", n_f=6)
    forcing_nt_array = namedtuple_from_names_values(forcing.data, forcing.variables)
    land_init = output.land_init
    output_array = output.data
    loc_forcing = getLocData(forcing_nt_array, space_ind[1])
    loc_forcing_t, loc_land = runTEMOne(selected_models, loc_forcing, land_init, tem_info)

    addErrorCatcher(loc_land, info.helpers.run.debug_model)

    # collect local data and create copies
    print_info(helpPrepTEM, @__FILE__, @__LINE__, "preallocating local, threaded, and spatial data", n_f=6)
    space_forcing = map([space_ind...]) do lsi
        getLocData(forcing_nt_array, lsi)
    end

    space_spinup_forcing = map(space_forcing) do loc_forcing
        getAllSpinupForcing(loc_forcing, info.spinup.sequence, tem_info);
    end

    space_output = map([space_ind...]) do lsi
        getLocData(output_array, lsi)
    end

    space_selected_models = [[selected_models for _ ∈ 1:length(space_ind)]...]

    forcing_nt_array = nothing

    run_helpers = (; space_selected_models, space_forcing, space_ind, space_spinup_forcing, loc_forcing_t, space_output, loc_land, output_vars=output.variables, tem_info)

    return run_helpers
end


function helpPrepTEM(selected_models, info, forcing::NamedTuple, observations::NamedTuple, output::NamedTuple, ::PreAllocArrayFD)
    run_helpers = helpPrepTEM(selected_models, info, forcing, output, PreAllocArrayFD())
    observations_nt_array = namedtuple_from_names_values(observations.data, observations.variables)

    space_observation = map([run_helpers.space_ind...]) do lsi
        getLocData(observations_nt_array, lsi)
    end
    run_helpers = (; run_helpers..., space_observation=space_observation)
    return run_helpers
end


function helpPrepTEM(selected_models, info, forcing::NamedTuple, output::NamedTuple, ::PreAllocArrayMT)

    run_helpers = helpPrepTEM(selected_models, info, forcing, output, PreAllocArray())

    forcing_helpers_with_parameter_set = updateForcingHelpers(deepcopy(forcing.helpers), info.optimization.run_options.n_threads_cost);

    output_mt = prepTEMOut(info, forcing_helpers_with_parameter_set)
    output_array_mt = output_mt.data

    space_ind_mt, _ = getSpatialInfo(forcing_helpers_with_parameter_set)

    space_output_mt = map([space_ind_mt...]) do lsi
        getLocData(output_array_mt, lsi)
    end

    run_helpers = (; run_helpers..., space_output_mt=space_output_mt, space_ind_mt=space_ind_mt, output_array_mt=output_array_mt, output_dims_mt=output_mt.dims, forcing_helpers_with_parameter_set=forcing_helpers_with_parameter_set)
    return run_helpers
end

function helpPrepTEM(selected_models, info, forcing::NamedTuple, output::NamedTuple, ::PreAllocStacked)
    
    # get the output things
    print_info(helpPrepTEM, @__FILE__, @__LINE__, "preparing spatial and tem helper", n_f=6)
    space_ind = getSpatialInfo(forcing, info.helpers.run.filter_nan_pixels)

    # generate vals for dispatch of forcing and output
    tem_info = getRunTEMInfo(info, forcing);

    ## run the model for one time step
    print_info(helpPrepTEM, @__FILE__, @__LINE__, "model run for one location and time step", n_f=6)
    land_init = output.land_init
    forcing_nt_array = namedtuple_from_names_values(forcing.data, forcing.variables)
    loc_forcing = getLocData(forcing_nt_array, space_ind[1])
    loc_spinup_forcing = getAllSpinupForcing(loc_forcing, info.spinup.sequence, tem_info);
    loc_forcing_t, loc_land = runTEMOne(selected_models, loc_forcing, land_init, tem_info)
    addErrorCatcher(loc_land, info.helpers.run.debug_model)

    output_vars = output.variables
    output_dims = output.dims

    space_selected_models = [[selected_models for _ ∈ 1:length(space_ind)]...]

    land_time_series = nothing
    run_helpers = (; loc_forcing, loc_forcing_t, loc_spinup_forcing, loc_land, land_time_series, space_selected_models, space_ind, output_dims, output_vars, tem_info)
    return run_helpers
end


function helpPrepTEM(selected_models, info, forcing::NamedTuple, output::NamedTuple, ::PreAllocTimeseries)
    run_helpers = helpPrepTEM(selected_models, info, forcing, output, PreAllocStacked())
    land_timeseries = Vector{typeof(run_helpers.loc_land)}(undef, tem_helpers.dates.size)
    run_helpers = set_namedtuple_field(run_helpers, (:land_timeseries, land_timeseries))
    return run_helpers
end


function helpPrepTEM(selected_models, info, forcing::NamedTuple, output::NamedTuple, ::PreAllocYAXArray)

    # generate vals for dispatch of forcing and output
    tem_info = getRunTEMInfo(info, forcing);
    # tem_info = @set tem_info.spinup = info.spinup.sequence

    loc_land = output.land_init
    output_vars = output.variables
    output_dims = output.dims
    run_helpers = (; loc_land, output_vars, output_dims, tem_info)
    if hasproperty(output, :parameter_dim)
        run_helpers = set_namedtuple_field(run_helpers, (:parameter_dim, output.parameter_dim))
    end
    return run_helpers
end

"""
    prepTEM(forcing::NamedTuple, info::NamedTuple)
    prepTEM(selected_models, forcing::NamedTuple, info::NamedTuple)
    prepTEM(selected_models, forcing::NamedTuple, observations::NamedTuple, info::NamedTuple)

Prepares the SINDBAD Terrestrial Ecosystem Model (TEM) for execution by setting up the necessary inputs, outputs, and configurations with different variants for different experimental setups.

# Arguments:
- `selected_models`: A tuple of all models selected in the given model structure.
- `forcing::NamedTuple`: A forcing NamedTuple containing the time series of environmental drivers for all locations.
- `observations::NamedTuple`: A NamedTuple containing observational data for model validation.
- `info::NamedTuple`: A nested NamedTuple containing necessary information, including:
    - Helpers for running the model.
    - Model configurations.
    - Spinup settings.

# Returns:
- `run_helpers`: A NamedTuple containing preallocated data and configurations required to run the TEM, including:
    - Spatial forcing data.
    - Spinup forcing data.
    - Output arrays.
    - Land variables.
    - Temporal and spatial indices.
    - Model and helper configurations.

# Notes:
- The function dynamically prepares the required data structures based on the specified `PreAllocputType` in `info.helpers.run.land_output_type`.
- It handles spatial and temporal data preparation, including filtering NaN pixels, initializing land variables, and setting up forcing and output arrays.
- This function is a key step in preparing the SINDBAD TEM for execution.

# Examples:
1. **Preparing TEM with observations**:
```julia
selected_models = (model1, model2)
forcing = (data = ..., variables = ...)
observations = (data = ..., variables = ...)
info = (helpers = ..., models = ..., spinup = ...)
run_helpers = prepTEM(selected_models, forcing, observations, info)
```

2. **Preparing TEM without observations**:
```julia
selected_models = (model1, model2)
forcing = (data = ..., variables = ...)
info = (helpers = ..., models = ..., spinup = ...)
run_helpers = prepTEM(selected_models, forcing, info)
```
"""
function prepTEM end

function prepTEM(forcing::NamedTuple, info::NamedTuple)
    selected_models = info.models.forward
    return prepTEM(selected_models, forcing, info)
end

function prepTEM(selected_models, forcing::NamedTuple, info::NamedTuple)
    print_info(prepTEM, @__FILE__, @__LINE__, "preparing to run terrestrial ecosystem model (TEM)", n_f=1)
    output = prepTEMOut(info, forcing.helpers)
    print_info(prepTEM, @__FILE__, @__LINE__, "  preparing helpers for running model experiment", n_f=4)
    run_helpers = helpPrepTEM(selected_models, info, forcing, output, info.helpers.run.land_output_type)
    print_info_separator()

    return run_helpers
end

function prepTEM(selected_models, forcing::NamedTuple, observations::NamedTuple, info::NamedTuple)
    print_info(prepTEM, @__FILE__, @__LINE__, "preparing to run terrestrial ecosystem model (TEM)", n_f=1)
    output = prepTEMOut(info, forcing.helpers)
    run_helpers = helpPrepTEM(selected_models, info, forcing, observations, output, info.helpers.run.land_output_type)
    print_info_separator()

    return run_helpers
end


"""
    runTEMOne(selected_models, forcing, output_array::AbstractArray, land_init, loc_ind, tem)

run the SINDBAD TEM for one time step

# Arguments:
- `selected_models`: a tuple of all models selected in the given model structure
- `loc_forcing`: a forcing NT for a single location
- `land_init`: initial SINDBAD land with all fields and subfields
- `tem`: a nested NT with necessary information of helpers, models, and spinup needed to run SINDBAD TEM and models

# Returns:
- `loc_forcing_t`: the forcing NT for the current time step
- `loc_land`: the SINDBAD land NT after a run of model for one time step. This contains all the variables from the selected models and their structure and type will remain the same across the experiment.
"""
function runTEMOne(selected_models, loc_forcing, land_init, tem)
    loc_forcing_t = getForcingForTimeStep(loc_forcing, loc_forcing, 1, tem.vals.forcing_types)
    loc_land = definePrecomputeTEM(selected_models, loc_forcing_t, land_init,
        tem.model_helpers)
    loc_land = computeTEM(selected_models, loc_forcing_t, loc_land, tem.model_helpers)
    # loc_land = drop_empty_namedtuple_fields(loc_land)
    loc_land = addSpinupLog(loc_land, tem.spinup_sequence, tem.run.store_spinup)
    # loc_land = definePrecomputeTEM(selected_models, loc_forcing_t, loc_land,
        # tem.model_helpers)
    # loc_land = precomputeTEM(selected_models, loc_forcing_t, loc_land,
        # tem.model_helpers)
    # loc_land = computeTEM(selected_models, loc_forcing_t, loc_land, tem.model_helpers)
    return loc_forcing_t, loc_land
end

function updateForcingHelpers(new_forcing_helpers, parameter_set_size)
    data_dimensions = new_forcing_helpers.dimensions
    insert!(data_dimensions.space, 1, "parameter_set")
    if !isnothing(data_dimensions.permute)
        insert!(data_dimensions.permute, 2, "parameter_set")
    end
    insert!(new_forcing_helpers.axes, 2, Pair(:parameter_set, 1:parameter_set_size))
    new_sizes = (; new_forcing_helpers.sizes..., parameter_set=parameter_set_size)
    new_forcing_helpers = set_namedtuple_field(new_forcing_helpers, (:sizes, new_sizes))
    return new_forcing_helpers
end
