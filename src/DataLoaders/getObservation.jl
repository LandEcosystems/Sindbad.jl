export getObservation

"""
    getAllConstraintData(nc, data_backend, data_path, default_info, v_info, data_sub_field, info; yax=nothing, use_data_sub=true)

Reads data from the observation file and returns the data, YAXArray, variable info, and bounds for the observation constraint.

# Arguments:
- `nc`: The file or NetCDF object containing the observation data.
- `data_backend`: The backend used to process the data (e.g., NetCDF, Zarr).
- `data_path`: The path to the observation data file.
- `default_info`: Default variable information for constraints.
- `v_info`: Variable-specific information for the observation constraint, which can overwrite `default_info`.
- `data_sub_field`: The subfield of the observation data to process (e.g., `:data`, `:qflag`, `:unc`).
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `yax`: (Optional) The base observation YAXArray.
- `use_data_sub`: A flag indicating whether to use the subfield of the observation constraint.

# Returns:
- `nc_sub`: The NetCDF object for the subfield.
- `yax_sub`: The YAXArray for the subfield.
- `v_info_sub`: The variable information for the subfield.
- `bounds_sub`: The bounds for the subfield.

# Notes:
- If the subfield is not provided or `use_data_sub` is `false`, default values are used.
- Handles quality flags, uncertainty, spatial weights, and selection masks for observation constraints.

# Examples
```jldoctest
julia> using Sindbad

julia> # Get constraint data for observations
julia> # nc_sub, yax_sub, v_info_sub, bounds_sub = getAllConstraintData(nc, data_backend, data_path, default_info, v_info, :data, info)
```
"""
function getAllConstraintData(nc, data_backend, data_path, default_info, v_info, data_sub_field, info; yax=nothing, use_data_sub=true)
    nc_sub = nothing
    yax_sub = nothing
    v_info_sub = nothing
    bounds_sub = nothing
    @debug "   $(data_sub_field)"
    get_it_from_path = false
    if hasproperty(v_info, data_sub_field) && use_data_sub
        get_it_from_path = true
        v_info_var = getfield(v_info, data_sub_field)
        if isnothing(v_info_var)
            get_it_from_path = false
        end
    end
    if get_it_from_path
        v_info_var = getfield(v_info, data_sub_field)
        v_info_sub = merge_namedtuple_prefer_nonempty(default_info, v_info_var)
        data_path_sub = getAbsDataPath(info, v_info_sub.data_path)
        nc_sub = nc
        nc_sub, yax_sub = getYaxFromSource(nc_sub, data_path, data_path_sub, v_info_sub.source_variable, info, data_backend)
        # @show v_info_sub
        v_op = v_info_sub.additive_unit_conversion ? " + " : " * "
        v_op = v_op * "$(v_info_sub.source_to_sindbad_unit)"
        v_string = "$(data_sub_field) ($(v_info_sub.sindbad_unit), $(v_info_sub.bounds)) = <$(v_info_sub.space_time_type)> `$(v_info_sub.source_variable)` ($(v_info_sub.source_unit)) $(v_op)"

        print_info(nothing, @__FILE__, @__LINE__, v_string, n_m=6)
        bounds_sub = v_info_sub.bounds
    else
        if data_sub_field == :qflag
            @debug "     no \"$(data_sub_field)\" field OR use_quality_flag=false in optimization settings"
        elseif data_sub_field == :unc
            @debug "     no \"$(data_sub_field)\" field OR use_uncertainty=false in optimization settings"
        elseif data_sub_field == :weight
            @debug "     no \"$(data_sub_field)\" field OR use_spatial_weight=false in optimization settings"
        else
            @debug "     no \"$(data_sub_field)\" field OR sel_mask=null in optimization settings"
        end
        if !isnothing(yax)
            print_info(nothing, @__FILE__, @__LINE__, "$(data_sub_field): ones(data)", n_m=6)
            nc_sub = nc
            yax_sub = map(x -> one(x), yax)
            v_info_sub = default_info
            bounds_sub = v_info_sub.bounds
        else
            error("no input yax is provided to set values as ones. Cannot conntinue. Change settings in optimization.json")
        end
    end
    return nc_sub, yax_sub, v_info_sub, bounds_sub
end


"""
    getObservation(info::NamedTuple, forcing_helpers::NamedTuple)

Processes observation data and returns a NamedTuple containing the observation data, dimensions, and variables.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `forcing_helpers`: A SINDBAD NamedTuple containing helper information for forcing data.

# Returns:
- A NamedTuple with the following fields:
  - `data`: The processed observation data as an input array.
  - `dims`: The dimensions of the observation data.
  - `variables`: A tuple of variable names for the observation data.

# Notes:
- Reads observation data from the path specified in the experiment configuration.

# Examples
```jldoctest
julia> using Sindbad

julia> # Load observation data from experiment configuration
julia> # observations = getObservation(info, forcing_helpers)
```
- Handles quality flags, uncertainty, spatial weights, and selection masks for each observation variable.
- Subsets and harmonizes the observation data based on the target dimensions and masks.
"""
function getObservation(info::NamedTuple, forcing_helpers::NamedTuple)
    observation_data_settings = info.experiment.data_settings.optimization
    forcing_data_settings = info.experiment.data_settings.forcing
    exe_rules_settings = info.experiment.exe_rules
    data_path = observation_data_settings.observations.default_observation.data_path
    data_backend = info.helpers.run.input_data_backend
    default_info = observation_data_settings.observations.default_observation
    tar_dims = getTargetDimensionOrder(info)

    nc_default = nothing

    if !isnothing(data_path)
        data_path = getAbsDataPath(info, data_path)
        print_info(getObservation, @__FILE__, @__LINE__, "default_observation_data_path: `$(data_path)`")
        nc_default = loadDataFile(data_path)
    end

    varnames = Symbol.(observation_data_settings.observational_constraints)

    yax_mask = nothing
    if :one_sel_mask ∈ keys(observation_data_settings)
        if !isnothing(observation_data_settings.one_sel_mask)
            mask_path = getAbsDataPath(info, observation_data_settings.one_sel_mask)
            _, yax_mask = getYaxFromSource(nothing, mask_path, nothing, "mask", info, data_backend)
            yax_mask = positive_mask(yax_mask)
        end
    end
    obscubes = []
    num_type = Val{info.helpers.numbers.num_type}()
    num_type_bool = Val{Bool}()

    print_info(getObservation, @__FILE__, @__LINE__, "getting observation variables. Units given in optimization settings are not strictly enforced but shown for reference. Bounds are applied after unit conversion...")
    map(varnames) do k

        vinfo = getproperty(observation_data_settings.observations.variables, k)
        print_info(nothing, @__FILE__, @__LINE__, "constraint: `$k`", n_m=4)

        src_var = vinfo.data.source_variable
        nc = nc_default
        nc, yax, vinfo_data, bounds_data = getAllConstraintData(nc, data_backend, data_path, default_info, vinfo, :data, info)

        # get quality flags data and use it later to mask observations. Set to value of 1 when :qflag field is not given for a data stream or all are turned off by setting optimizatio.optimization.observations.use_quality_flag to false
        nc_qc, yax_qc, vinfo_qc, bounds_qc = getAllConstraintData(nc, data_backend, data_path, default_info, vinfo, :qflag, info; yax=yax, use_data_sub=observation_data_settings.observations.use_quality_flag)

        # get uncertainty data and add to observations. Set to value of 1 when :unc field is not given for a data stream or all are turned off by setting observation_data_settings.use_uncertainty to false
        nc_unc, yax_unc, vinfo_unc, bounds_unc = getAllConstraintData(nc, data_backend, data_path, default_info, vinfo, :unc, info; yax=yax, use_data_sub=observation_data_settings.observations.use_uncertainty)

        nc_wgt, yax_wgt, vinfo_wgt, bounds_wgt = getAllConstraintData(nc, data_backend, data_path, default_info, vinfo, :weight, info; yax=yax, use_data_sub=observation_data_settings.observations.use_spatial_weight)

        _, yax_mask_v, vinfo_mask, bounds_mask = getAllConstraintData(nc, data_backend, data_path, default_info, vinfo, :sel_mask, info; yax=yax)
        yax_mask_v = positive_mask(yax_mask_v)
        if !isnothing(yax_mask)
            yax_mask_v .= yax_mask .* yax_mask_v
        end
        print_info(nothing, @__FILE__, @__LINE__, "harmonize/subset...", n_m=6)
        @debug "      qflag"
        cyax_qc = subsetAndProcessYax(yax_qc, yax_mask_v, tar_dims, vinfo_qc, info, num_type; clean_data=false)
        @debug "      data"
        cyax = subsetAndProcessYax(yax, yax_mask, tar_dims, vinfo_data, info, num_type; fill_nan=true, yax_qc=cyax_qc, bounds_qc=bounds_qc)
        @debug "      unc"
        cyax_unc = subsetAndProcessYax(yax_unc, yax_mask, tar_dims, vinfo_unc, info, num_type; fill_nan=true, yax_qc=cyax_qc, bounds_qc=bounds_qc)
        @debug "      weight"
        cyax_wgt = subsetAndProcessYax(yax_wgt, yax_mask, tar_dims, vinfo_wgt, info, num_type; fill_nan=true, yax_qc=cyax_qc, bounds_qc=bounds_qc)
        @debug "      mask"
        yax_mask_v = subsetAndProcessYax(yax_mask_v, yax_mask_v, tar_dims, vinfo_mask, info, num_type_bool; clean_data=false)

        push!(obscubes, cyax)
        push!(obscubes, cyax_unc)
        push!(obscubes, yax_mask_v)
        push!(obscubes, cyax_wgt)
    end
    print_info(getObservation, @__FILE__, @__LINE__, "getting observation helpers...", n_m=2)
    @debug "getObservation: getting observation dimensions..."
    indims = getDataDims.(obscubes, Ref(forcing_data_settings.data_dimension.space))
    @debug "getObservation: getting number of time steps..."
    nts = forcing_helpers.sizes
    @debug "getObservation: getting variable name..."
    varnames_all = []
    for v ∈ varnames
        push!(varnames_all, v)
        push!(varnames_all, Symbol(string(v) * "_σ"))
        push!(varnames_all, Symbol(string(v) * "_mask"))
        push!(varnames_all, Symbol(string(v) * "_weight"))
    end
    input_array_type = getfield(Types, to_uppercase_first(exe_rules_settings.input_array_type, "Input"))()
    print_info_separator()

    return (; data=getInputArrayOfType(obscubes, input_array_type), dims=indims, variables=Tuple(varnames_all))
end
