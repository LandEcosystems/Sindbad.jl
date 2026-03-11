```@docs
Sindbad.Setup
```
## Functions

### backScaleParameters
```@docs
backScaleParameters
```

:::details Code

```julia
function backScaleParameters end

function backScaleParameters(parameter_vector_scaled, parameter_table, ::ScaleNone)
    return parameter_vector_scaled
end

function backScaleParameters(parameter_vector_scaled, parameter_table, ::ScaleNone)
    return parameter_vector_scaled
end

function backScaleParameters(parameter_vector_scaled, parameter_table, ::ScaleDefault)
    parameter_vector_scaled = abs.(parameter_table.initial) .* parameter_vector_scaled
    return parameter_vector_scaled
end

function backScaleParameters(parameter_vector_scaled, parameter_table, ::ScaleBounds)
    ub = parameter_table.upper  # upper bounds
    lb = parameter_table.lower   # lower bounds
    parameter_vector_scaled .= lb + (ub - lb) .* parameter_vector_scaled
    return parameter_vector_scaled
end
```

:::


----

### checkParameterBounds
```@docs
checkParameterBounds
```

:::details Code

```julia
function checkParameterBounds(p_names, parameter_values, lower_bounds, upper_bounds, _sc::ParameterScaling; p_units=nothing, show_info=false, model_names=nothing)
    if show_info
        print_info(checkParameterBounds, @__FILE__, @__LINE__, "checking Parameter Bounds")
        if nameof(typeof(_sc)) == :ScaleNone
            print_info(nothing, @__FILE__, @__LINE__, "→→→    no scaling applied. The values and bounds are original/input values, while their units, when provided, are scaled to match the model run time steps and may differ from the original units in the model when @timescale of the parameter is different from the model run time step.")
        else
            print_info(nothing, @__FILE__, @__LINE__, "→→→    $(nameof(typeof(_sc))) scaling applied. The values and bounds are scaled values, while their units, when provided, are scaled to match the model run time steps and may differ from the original units in the model when @timescale of the parameter is different from the model run time step. Check info.models.parameter_table for interpreting parameter values in original/input units.")
        end
    end
    for (i,n) in enumerate(p_names)
        in_range = checkInRange(n, parameter_values[i], lower_bounds[i], upper_bounds[i], show_info)
        if !in_range
            error("$(String(n)) => value=$(parameter_values[i]) [lower_bound=$(lower_bounds[i]), upper_bound=$(upper_bounds[i])] violates the parameter bounds requirement (lower_bound <= value <= upper_bound). Fix the bounds in the given model ($(model_names[i])) or in the parameters input to continue.")
        end
        if show_info
            ps = String(n)
            if !isnothing(model_names)
                ps = "`$(String(model_names[i]))`.jl: `$(String(n))`" 
            end
            units_str = ""
            if !isnothing(p_units)
                units_str = p_units[i] == "" ? "unitless" : "$(p_units[i])"
                units_str = "(units: $(units_str))"
            end
            print_info(nothing, @__FILE__, @__LINE__, "$(ps) => $(parameter_values[i]) [$(lower_bounds[i]), $(upper_bounds[i])] $units_str", n_f=6)

        end
    end
end
```

:::


----

### convertRunFlagsToTypes
```@docs
convertRunFlagsToTypes
```

:::details Code

```julia
function convertRunFlagsToTypes(info)
    new_run = (;)
    dr = deepcopy(info.settings.experiment.flags)
    for pr in propertynames(dr)
        prf = getfield(dr, pr)
        prtoset = nothing
        if isa(prf, NamedTuple)
            st = (;)
            for prs in propertynames(prf)
                prsf = getfield(prf, prs)
                st = set_namedtuple_field(st, (prs, getTypeInstanceForFlags(prs, prsf)))
            end
            prtoset = st
        else
            prtoset = getTypeInstanceForFlags(pr, prf)
        end
        new_run = set_namedtuple_field(new_run, (pr, prtoset))
    end
    return new_run
end
```

:::


----

### createArrayofType
```@docs
createArrayofType
```

:::details Code

```julia
function createArrayofType end

function createArrayofType(input_values, pool_array, num_type, indx, ismain, ::ModelArrayView)
    if ismain
        num_type.(input_values)
    else
        @view pool_array[[indx...]]
    end
end

function createArrayofType(input_values, pool_array, num_type, indx, ismain, ::ModelArrayView)
    if ismain
        num_type.(input_values)
    else
        @view pool_array[[indx...]]
    end
end

function createArrayofType(input_values, pool_array, num_type, indx, ismain, ::ModelArrayArray)
    return num_type.(input_values)
end

function createArrayofType(input_values, pool_array, num_type, indx, ismain, ::ModelArrayStaticArray)
    input_typed = typeof(num_type(1.0)) === eltype(input_values) ? input_values : num_type.(input_values) 
    return SVector{length(input_values)}(input_typed)
    # return SVector{length(input_values)}(num_type(ix) for ix ∈ input_values)
end
```

:::


----

### createInitLand
```@docs
createInitLand
```

:::details Code

```julia
function createInitLand(pool_info, tem)
    print_info(createInitLand, @__FILE__, @__LINE__, "creating Initial Land...")
    init_pools = createInitPools(pool_info, tem.helpers)
    initial_states = createInitStates(pool_info, tem.helpers)
    out = (; fluxes=(;), pools=(; init_pools..., initial_states...), states=(;), diagnostics=(;), properties=(;), models=(;), constants=(;))
    sortedModels = sort([_sm for _sm ∈ tem.models.selected_models.model])
    for model ∈ sortedModels
        out = set_namedtuple_field(out, (model, (;)))
    end
    return out
end
```

:::


----

### createInitPools
```@docs
createInitPools
```

:::details Code

```julia
function createInitPools(info_pools::NamedTuple, tem_helpers::NamedTuple)
    init_pools = (;)
    for element ∈ propertynames(info_pools)
        props = getfield(info_pools, element)
        model_array_type = getfield(Types, to_uppercase_first(string(getfield(props, :arraytype)), "ModelArray"))()
        var_to_create = getfield(props, :create)
        initial_values = getfield(props, :initial_values)
        for tocr ∈ var_to_create
            input_values = deepcopy(getfield(initial_values, tocr))
            init_pools = set_namedtuple_field(init_pools, (tocr, createArrayofType(input_values, Nothing[], tem_helpers.numbers.num_type, nothing, true, model_array_type)))
        end
        to_combine = getfield(getfield(info_pools, element), :combine)
        if to_combine.docombine
            combined_pool_name = to_combine.pool
            zix_pool = getfield(props, :zix)
            components = keys(zix_pool)
            pool_array = getfield(init_pools, combined_pool_name)
            for component ∈ components
                if component != combined_pool_name
                    indx = getfield(zix_pool, component)
                    input_values = deepcopy(getfield(initial_values, component))
                    compdat = createArrayofType(input_values, pool_array, tem_helpers.numbers.num_type, indx, false, model_array_type)
                    init_pools = set_namedtuple_field(init_pools, (component, compdat))
                end
            end
        end
    end
    return init_pools
end
```

:::


----

### createInitStates
```@docs
createInitStates
```

:::details Code

```julia
function createInitStates(info_pools::NamedTuple, tem_helpers::NamedTuple)
    initial_states = (;)
    for element ∈ propertynames(info_pools)
        props = getfield(info_pools, element)
        var_to_create = getfield(props, :create)
        additional_state_vars = (;)
        if hasproperty(props, :state_variables)
            additional_state_vars = getfield(props, :state_variables)
        end
        initial_values = getfield(props, :initial_values)
        model_array_type = getfield(Types, to_uppercase_first(string(getfield(props, :arraytype)), "ModelArray"))()
        for tocr ∈ var_to_create
            for avk ∈ keys(additional_state_vars)
                avv = getproperty(additional_state_vars, avk)
                Δtocr = Symbol(string(avk) * string(tocr))
                vals = one.(getfield(initial_values, tocr)) *                                 tem_helpers.numbers.num_type(avv)
                newvals = createArrayofType(vals, Nothing[], tem_helpers.numbers.num_type, nothing, true, model_array_type)
                initial_states = set_namedtuple_field(initial_states, (Δtocr, newvals))
            end
        end
        to_combine = getfield(getfield(info_pools, element), :combine)
        if to_combine.docombine
            combined_pool_name = Symbol(to_combine.pool)
            for avk ∈ keys(additional_state_vars)
                avv = getproperty(additional_state_vars, avk)
                Δ_combined_pool_name = Symbol(string(avk) * string(combined_pool_name))
                zix_pool = getfield(props, :zix)
                components = keys(zix_pool)
                Δ_pool_array = getfield(initial_states, Δ_combined_pool_name)
                for component ∈ components
                    if component != combined_pool_name
                        Δ_component = Symbol(string(avk) * string(component))
                        indx = getfield(zix_pool, component)
                        Δ_compdat = createArrayofType((one.(getfield(initial_values, component))) .* tem_helpers.numbers.num_type(avv), Δ_pool_array, tem_helpers.numbers.num_type, indx, false, model_array_type)
                        initial_states = set_namedtuple_field(initial_states, (Δ_component, Δ_compdat))
                    end
                end
            end
        end
    end
    return initial_states
end
```

:::


----

### createNestedDict
```@docs
createNestedDict
```

:::details Code

```julia
function createNestedDict(dict::AbstractDict)
    nested_dict = Dict()
    for kii ∈ keys(dict)
        key_list = split(kii, ".")
        key_dict = Dict()
        for key_index ∈ reverse(eachindex(key_list))
            subkey = key_list[key_index]
            if subkey == first(key_list)
                subkey_name = subkey
            else
                subkey_name = subkey * string(key_index)
            end
            if subkey == last(key_list)
                key_dict[subkey_name] = dict[kii]
            else
                if !haskey(key_dict, subkey_name)
                    key_dict[subkey_name] = Dict()
                    key_dict[subkey_name][key_list[key_index+1]] = key_dict[key_list[key_index+1]*string(key_index+1)]
                else
                    tmp = Dict()
                    tmp[subkey_name] = key_dict[key_list[key_index+1]*string(key_index + 1)]
                end
                delete!(key_dict, key_list[key_index+1] * string(key_index + 1))
                delete!(nested_dict, key_list[key_index+1] * string(key_index + 1))
            end
            nested_dict = deepMerge(nested_dict, key_dict)
        end
    end
    return nested_dict
end
```

:::


----

### deepMerge
```@docs
deepMerge
```

:::details Code

```julia
function deepMerge end

deepMerge(d::AbstractDict...) = merge(deepMerge, d...)
deepMerge(d...) = d[end]

"""
    getRootDirs(local_root, sindbad_experiment)

Determines the root directories for the SINDBAD framework and the experiment.

# Arguments:
- `local_root`: The local root directory of the SINDBAD project.
- `sindbad_experiment`: The path to the experiment configuration file.

# Returns:
- A NamedTuple containing the root directories for the experiment, SINDBAD, and settings.
"""
function getRootDirs(local_root, sindbad_experiment)
    # sindbad_root = join(split(local_root, path_separator)[1:(end-2)] |> collect, path_separator)
    exp_base_path = dirname(sindbad_experiment)
    root_dir = (; experiment=normalize_path_separator(local_root), settings=normalize_path_separator(exp_base_path))
    # root_dir = (; experiment=local_root, sindbad=sindbad_root, settings=exp_base_path)
    return root_dir
end
```

:::


----

### filterParameterTable
```@docs
filterParameterTable
```

:::details Code

```julia
function filterParameterTable(parameter_table::Table; prop_name::Symbol=:model, prop_values::Union{Vector{Symbol},Symbol}=:all)
    if prop_values == :all
        return parameter_table
    elseif isa(prop_values, Symbol)
        return filter(row -> getproperty(row, prop_name) == prop_values, parameter_table)
    else
        return filter(row -> getproperty(row, prop_name) in prop_values, parameter_table)
    end
end
```

:::


----

### generateSindbadApproach
```@docs
generateSindbadApproach
```

:::details Code

```julia
function generateSindbadApproach(model_name::Symbol, model_purpose::String, appr_name::Symbol, appr_purpose::String, n_parameters::Int; methods=(:define, :precompute, :compute, :update), force_over_write=:none)
    was_model_created = false
    was_approach_created = false
    over_write_model = false
    over_write_appr = false
    if force_over_write == :none
        @info "Overwriting of type and file is off. Only new objects will be created"
    elseif force_over_write == :model
        over_write_model = true
        @warn "Overwriting of type and file for Model is permitted. Continue with care."
    elseif force_over_write == :approach
        over_write_appr = true
        @warn "Overwriting of type and file for Approach is permitted. Continue with care."
    elseif force_over_write == :both
        @warn "Overwriting of both type and files for Model and Approach are permitted. Continue with extreme care."
        over_write_model = true
        over_write_appr = true
    else
        error("force_over_write can only be one of (:none, :both, :model, :approach)")
    end    

    if !startswith(string(appr_name), string(model_name)*"_")
        @warn "the name $(appr_name) does not start with $(model_name), which is against the SINDBAD model component convention. Using $(model_name)_$(appr_name) as the name of the approach."
        appr_name = Symbol(string(model_name) *"_"* string(appr_name))
    end
    model_type_exists = model_name in nameof.(subtypes(LandEcosystem)) 
    model_path = joinpath(split(pathof(SindbadTEM),"/SindbadTEM.jl")[1], "Processes", "$(model_name)", "$(model_name).jl")
    model_path_exists = isfile(model_path)
    appr_path = joinpath(split(pathof(SindbadTEM),"/SindbadTEM.jl")[1], "Processes", "$(model_name)", "$(appr_name).jl")
    appr_path_exists = isfile(appr_path)

    model_path_exists = over_write_model ? false : model_path_exists

    model_exists = false
    if model_type_exists && model_path_exists
        @info "both model_path and model_type exist. No need to create the model."
        model_exists = true
    elseif model_type_exists && !model_path_exists
        @warn "model_type exists but (model_path does not exist || force_over_write is enabled with :$(force_over_write)). If force_over_write is not enabled, fix the inconsistency by moving the definition of th type to the file itself."
    elseif !model_type_exists && model_path_exists
        @warn "model_path exists but model_type does not exist. Fix this inconsistency by defining the type in the file."
        model_exists = true
    else
        @info "both model_type and (model_path do not exist || force_over_write is enabled with :$(force_over_write)). Model will be created."
    end

    if model_exists
        @info "Not generating model "
    else
        @info "Generating a new model: $(model_name) at:\n$(appr_path)"
        confirm_ = Base.prompt("Continue: y | n")
        if startswith(confirm_, "y")
            @info "Generating model code:"
            m_string=generateModelCode(model_name, model_purpose)
            mkpath(dirname(model_path))
            @info "Writing model code:"
            open(model_path, "w") do model_file
                write(model_file, m_string)
            end
            @info "success: $(model_path)"
            was_model_created = true
        end
    end

    appr_exists = false
    appr_type_exists = false
    if hasproperty(SindbadTEM.Processes, model_name)
        model_type = getproperty(SindbadTEM.Processes, model_name)
        appr_types = nameof.(subtypes(model_type))
        appr_type_exists = appr_name in appr_types
    end

    appr_path_exists = over_write_appr ? false : appr_path_exists

    if appr_type_exists && appr_path_exists
        @info "both appr_path and appr_type exist. No need to create the approach."
        appr_exists = true
    elseif appr_type_exists && !appr_path_exists
        @warn "appr_type exists but (appr_path does not exist || force_over_write is enabled with :$(force_over_write))). If force_over_write is not enabled, fix this inconsistency by defining the type in the file itself."
    elseif !appr_type_exists && appr_path_exists
        @warn "appr_path exists but appr_type does not exist. Fix this inconsistency by defining the type in the file."
    else
        @info "both appr_type and (appr_path do not exist || force_over_write is enabled with :$(force_over_write)). Approach will be created."
    end
    
    if appr_exists
        @info "Not generating approach."
    else
        appr_path = joinpath(split(pathof(SindbadTEM),"/SindbadTEM.jl")[1], "Processes", "$(model_name)", "$(appr_name).jl")
        @info "Generating a new approach: $(appr_name) for existing model: $(model_name) at:\n$(appr_path)"
        confirm_ = Base.prompt("Continue: y | n")
        if startswith(confirm_, "y")
            @info "Generating code:"
            appr_string = generateApproachCode(model_name, appr_name, appr_purpose, n_parameters; methods=methods)
            @info "Writing code:"
            open(appr_path, "w") do appr_file
                write(appr_file, appr_string)
            end
            @info "success: $(appr_path)"
            was_approach_created = true
        else
            @info "Not generating approach file due to user input."
        end
    end

    ## append the tmp_precompile_placeholder file so that Sindbad is forced to precompile in the next run_helpers
    if was_model_created || was_approach_created
        # Specify the file path
        file_path = joinpath(split(pathof(SindbadTEM),"/SindbadTEM.jl")[1], "tmp_precompile_placeholder.jl")

        # The line you want to add
        date = strip(read(`date +%d.%m.%Y`, String));

        new_lines = []
        if was_model_created
            new_line = "# - $(date): created a model $model_path.\n"
            push!(new_lines, new_line)
        end

        if was_approach_created
            new_line = "# - $(date): created an approach $appr_path.\n"
            push!(new_lines, new_line)
        end

        # Open the file in append mode
        open(file_path, "a") do file
            foreach(new_lines) do new_line
                write(file, new_line)
            end
        end  

    end
    return nothing
end
```

:::


----

### getAbsDataPath
```@docs
getAbsDataPath
```

:::details Code

```julia
function getAbsDataPath(info, data_path)
    if startswith(data_path, "http") || startswith(data_path, "s3://")
        return data_path
    end
    if !isabspath(data_path)
        d_data_path = getSindbadDataDepot(local_data_depot=data_path)
        if data_path == d_data_path
            data_path = joinpath(info.experiment.dirs.experiment, data_path)
        else
            data_path = joinpath(d_data_path, data_path)
        end
    end
    return data_path
end
```

:::


----

### getConfiguration
```@docs
getConfiguration
```

:::details Code

```julia
function getConfiguration(sindbad_experiment::String; replace_info=Dict())
    local_root = dirname(Base.active_project())
    if !isabspath(sindbad_experiment)
        sindbad_experiment = joinpath(local_root, sindbad_experiment)
    end
    roots = getRootDirs(local_root, sindbad_experiment)
    roots = (; roots..., sindbad_experiment)
    info = nothing
    if endswith(sindbad_experiment, ".json")
        info_exp = getExperimentConfiguration(sindbad_experiment; replace_info=replace_info)
        info = readConfiguration(info_exp, roots.settings)
    elseif endswith(sindbad_experiment, ".jld2")
        #todo running from the jld2 file here still does not work because the loaded info is a named tuple and replacing the fields will not work due to issues with merge and creating a dictionary from nested namedtuple
        # info = Dict(pairs(load(sindbad_experiment)["info"]))
        info = load(sindbad_experiment)["info"]
    else
        error(
            "sindbad can only be run with either a json or a jld2 data file. Provide a correct experiment file"
        )
    end
    if !isempty(replace_info)
        non_exp_dict = filter(x -> !startswith(first(x), "experiment"), replace_info)
        if !isempty(non_exp_dict)
            info = replaceInfoFields(info, non_exp_dict)
        end
    end
    if !haskey(info["experiment"]["basics"]["config_files"], "optimization")
        @warn "The config files in experiment_json and changes in replace_info do not include optimization_json. But, the settings for flags to run_optimization [set as $(info["experiment"]["flags"]["run_optimization"])] and/or calc_cost [set as $(info["experiment"]["flags"]["calc_cost"])] are set to true. These flags will be set to false from now on. The experiment will not run as intended further downstream. Cannot run optimization or calculate cost without the optimization settings. "
        info["experiment"]["flags"]["run_optimization"] = false
        info["experiment"]["flags"]["calc_cost"] = false
    end

    new_info = DataStructures.OrderedDict()
    new_info["settings"] = DataStructures.OrderedDict()
    for (k,v) in info
        new_info["settings"][k] = v
    end
    # @show keys(info)
    if !endswith(sindbad_experiment, ".jld2")
        infoTuple = dict_to_namedtuple(new_info)
    end
    infoTuple = (; infoTuple..., temp=(; experiment=(; dirs=roots)))

    print_info_separator()

    return infoTuple
    # return info
end
```

:::


----

### getConstraintNames
```@docs
getConstraintNames
```

:::details Code

```julia
function getConstraintNames(optim::NamedTuple)
    obs_vars = Symbol.(optim.observational_constraints)
    model_vars = String[]
    optim_vars = (;)
    for v ∈ obs_vars
        vinfo = getproperty(optim.observations.variables, v)
        push!(model_vars, vinfo.model_full_var)
        vf, vvar = Symbol.(split(vinfo.model_full_var, "."))
        optim_vars = set_namedtuple_field(optim_vars, (v, tuple(vf, vvar)))
    end
    store_vars = getVariableGroups(model_vars)
    return obs_vars, optim_vars, store_vars, model_vars
end
```

:::


----

### getCostOptions
```@docs
getCostOptions
```

:::details Code

```julia
function getCostOptions(optim_info::NamedTuple, vars_info, tem_variables, number_helpers, dates_helpers)
    varlist = Symbol.(optim_info.observational_constraints)
    agg_type = []
    time_aggrs = []
    aggr_funcs = []
    all_costs = map(varlist) do v
        merge_namedtuple_prefer_nonempty(optim_info.observations.default_cost, getfield(getfield(optim_info.observations.variables, v), :cost_options))
    end
    all_options = []
    push!(all_options, varlist)
    prop_names = keys(all_costs[1])
    props_to_keep = (:cost_metric, :spatial_weight, :cost_weight, :temporal_data_aggr, :aggr_obs, :aggr_order, :min_data_points, :spatial_data_aggr, :spatial_cost_aggr, :aggr_func,)
    for (pn, prop) ∈ enumerate(props_to_keep)
        prop_array = []
        for vn ∈ eachindex(varlist)
            sel_opt=all_costs[vn]
            sel_value = sel_opt[prop]
            if (sel_value isa Number) && !(sel_value isa Bool)
                sel_value = number_helpers.num_type(sel_value)
            elseif sel_value isa Bool
                sel_value=getTypeInstanceForFlags(prop, sel_value, "Do")
            elseif sel_value isa String && (prop == :cost_metric)
                sel_value = getTypeInstanceForCostMetric(ErrorMetrics, sel_value)
            elseif sel_value isa String && (prop ∈ (:aggr_order, :spatial_data_aggr))
                sel_value = getTypeInstanceForCostMetric(Types, sel_value)
            end
            push!(prop_array, sel_value)
            if prop == :temporal_data_aggr
                t_a = sel_value
                to_push_type = TimeNoDiff()
                if endswith(lowercase(t_a), "_anomaly") || endswith(lowercase(t_a), "_iav")
                    to_push_type = TimeDiff()
                end
                push!(agg_type, to_push_type)
                push!(time_aggrs, sel_value)
            end
            if prop == :aggr_func
                push!(aggr_funcs, sel_value)
            end
        end
        if prop in props_to_keep
            push!(all_options, prop_array)
        end
    end
    mod_vars = vars_info.model
    mod_field = [Symbol(split(_a, ".")[1]) for _a in mod_vars]
    mod_subfield = [Symbol(split(_a, ".")[2]) for _a in mod_vars]
    mod_ind = collect(1:length(varlist))
    obs_sn = [i for i in mod_ind]
    obs_ind = [i + 3 * (i - 1) for i in mod_ind]

    mod_ind = [findfirst(s -> first(s) === mf && last(s) === msf, tem_variables) for (mf, msf) in zip(mod_field, mod_subfield)]
    # map(cost_option_table) do cost_option
    #     # @show cost_option
    #     new_mod_ind = findfirst(s -> first(s) === cost_option.mod_field && last(s) === cost_option.mod_subfield, tem_variables)
    #     cost_option = Accessors.@set cost_option.mod_ind = new_mod_ind
    # end

    agg_indices = []
    for (i, _aggr) in enumerate(time_aggrs)
        aggr_func = getAggrFunc(aggr_funcs[i])
        _aggr_name = string(_aggr)
        skip_sampling = false
        if startswith(_aggr_name, dates_helpers.temporal_resolution)
            skip_sampling = true
        end
        aggInd = create_TimeSampler(dates_helpers.range, to_uppercase_first(_aggr, "Time"), aggr_func, skip_sampling)
        push!(agg_indices, aggInd)
    end
    push!(all_options, obs_ind)
    push!(all_options, obs_sn)
    push!(all_options, mod_ind)
    push!(all_options, mod_field)
    push!(all_options, mod_subfield)
    push!(all_options, agg_indices)
    push!(all_options, agg_type)
    all_props = [:variable, props_to_keep..., :obs_ind, :obs_sn, :mod_ind, :mod_field, :mod_subfield, :temporal_aggr, :temporal_aggr_type]
    return (; Pair.(all_props, all_options)...)
end
```

:::


----

### getDepthDimensionSizeName
```@docs
getDepthDimensionSizeName
```

:::details Code

```julia
function getDepthDimensionSizeName(v_full_pair, info::NamedTuple)
    v_full_str = getVariableString(v_full_pair)
    v_full_sym = Symbol(v_full_str)
    v_name = split(v_full_str, '.')[end]
    dim_size = 1
    dim_name = v_name * "_idx"
    tmp_vars = nothing
    tmp_vars = info.settings.experiment.model_output.variables
    if v_full_sym in keys(tmp_vars)
        v_dim = tmp_vars[v_full_sym]
        dim_size = 1
        dim_name = v_name * "_idx"
        if !isnothing(v_dim) && isa(v_dim, String)
            dim_name = v_dim
        end
        if isnothing(v_dim)
            dim_size = dim_size
        elseif isa(v_dim, Int64)
            dim_size = v_dim
        elseif isa(v_dim, String)
            if Symbol(v_dim) in keys(info.settings.experiment.model_output.depth_dimensions)
                dim_size_K = getfield(info.settings.experiment.model_output.depth_dimensions, Symbol(v_dim))
                if isa(dim_size_K, Int64)
                    dim_size = dim_size_K
                elseif isa(dim_size_K, String)
                    dim_size = getPoolSize(info.temp.helpers.pools, Symbol(dim_size_K))
                end
            else
                error(
                    "The output depth dimension for $(v_name) is specified as $(v_dim) but this key does not exist in depth_dimensions. Either add it to depth_dimensions or add a numeric value."
                )
            end
        else
            error(
                "The depth dimension for $(v_name) is specified as $(typeof(v_dim)). Only null, integers, or string keys to depth_dimensions are accepted."
            )
        end
    end
    return dim_size, dim_name
end
```

:::


----

### getDepthInfoAndVariables
```@docs
getDepthInfoAndVariables
```

:::details Code

```julia
function getDepthInfoAndVariables(info, output_vars)
    out_vars_pairs = Tuple(getVariablePair.(output_vars))
    depth_info = map(out_vars_pairs) do vname_full
        getDepthDimensionSizeName(vname_full, info)
    end
    output_info=(; info.output..., depth_info, variables=out_vars_pairs)
    return output_info
end
```

:::


----

### getExperimentConfiguration
```@docs
getExperimentConfiguration
```

:::details Code

```julia
function getExperimentConfiguration(experiment_json::String; replace_info=Dict())
    parseFile = parsefile(experiment_json; dicttype=DataStructures.OrderedDict)
    info = DataStructures.OrderedDict()
    info["experiment"] = DataStructures.OrderedDict()
    for (k, v) ∈ parseFile
        info["experiment"][k] = v
    end
    if !isempty(replace_info)
        exp_dict = filter(x -> startswith(first(x), "experiment"), replace_info)
        if !isempty(exp_dict)
            info = replaceInfoFields(info, exp_dict)
        end
    end
    return info
end
```

:::


----

### getExperimentInfo
```@docs
getExperimentInfo
```

:::details Code

```julia
function getExperimentInfo(sindbad_experiment::String; replace_info=Dict())
    replace_info_text = isempty(replace_info) ? "none" : " $(Tuple(keys(replace_info)))"
    print_info_separator()
    
    print_info(getExperimentInfo, @__FILE__, @__LINE__, "loading experiment configurations", n_m=1)
    print_info(nothing, @__FILE__, @__LINE__, "→→→    experiment_path: `$(sindbad_experiment)`", n_m=1)

    print_info(nothing, @__FILE__, @__LINE__, "→→→    replace_info_fields: `$(replace_info_text)`", n_m=1)
    info = getConfiguration(sindbad_experiment; replace_info=deepcopy(replace_info))

    info = setupInfo(info)
    saveInfo(info, info.helpers.run.save_info)
    setDebugErrorCatcher(info.helpers.run.catch_model_errors)
    return info
end
```

:::


----

### getGlobalAttributesForOutCubes
```@docs
getGlobalAttributesForOutCubes
```

:::details Code

```julia
function getGlobalAttributesForOutCubes(info)
    os = Sys.iswindows() ? "Windows" : Sys.isapple() ? "macOS" : Sys.islinux() ? "Linux" : "unknown"
    simulation_by = Sys.iswindows() ? ENV["USERNAME"] : ENV["USER"]
    io = IOBuffer()
    versioninfo(io)
    str = String(take!(io))
    julia_info = split(str, "\n")

    # io = IOBuffer()
    # Pkg.status("Sindbad", io=io)
    # sindbad_version = String(take!(io))
    global_attr = Dict(
        "simulation_by" => simulation_by,
        "experiment" => info.temp.experiment.basics.name,
        "domain" => info.temp.experiment.basics.domain,
        "date" => string(Date(now())),
        # "SINDBAD" => sindbad_version,
        "machine" => Sys.MACHINE,
        "os" => os,
        "host" => gethostname(),
        "julia" => string(VERSION),
    )
    return global_attr
end
```

:::


----

### getNumberType
```@docs
getNumberType
```

:::details Code

```julia
function getNumberType end

function getNumberType(t::String)
    ttype = eval(Meta.parse(t))
    return ttype
end

function getNumberType(t::String)
    ttype = eval(Meta.parse(t))
    return ttype
end

function getNumberType(t::DataType)
    return t
end
```

:::


----

### getOptimizationParametersTable
```@docs
getOptimizationParametersTable
```

:::details Code

```julia
function getOptimizationParametersTable(parameter_table_all::Table, model_parameter_default, optimization_parameters)
    parameter_list = []
    parameter_keys = []
    if isa(optimization_parameters, NamedTuple)
        parameter_keys = keys(optimization_parameters)
    else
        parameter_keys = optimization_parameters
    end
    parameter_list = replaceCommaSeparatedParams(parameter_keys)
    missing_parameters = filter(x -> !(x in parameter_table_all.name_full), parameter_list)
    if !isempty(missing_parameters)
        error("Model Inconsistency: $([missing_parameters...]) parameter(s) not found in the selected model structure. Check the model structure in model_structure.json to include the parameter(s) or change model_parameters_to_optimize in optimization.json to exclude the parameter(s).")
    end
    parameter_table_all_filtered = filter(row -> row.name_full in parameter_list, parameter_table_all)
    num_type = typeof(parameter_table_all_filtered.default[1])
    is_ml = parameter_table_all_filtered.is_ml
    dist = parameter_table_all_filtered.dist
    p_dist = parameter_table_all_filtered.p_dist
    for (p_ind, p_key) ∈ enumerate(parameter_keys)
        p_field = nothing
        was_default_used = false
        if isa(optimization_parameters, NamedTuple)
            p_field = getproperty(optimization_parameters, p_key)
            if isnothing(p_field)
                p_field = model_parameter_default
                was_default_used = true
            end
        else 
            was_default_used = true
            p_field = model_parameter_default
        end
        if !isnothing(p_field)
            if hasproperty(p_field, :is_ml)
                ml_json = getproperty(p_field, :is_ml)
                is_ml[p_ind] = ml_json
            end
            if hasproperty(p_field, :distribution)
                nd_json = getproperty(p_field, :distribution)
                dist[p_ind] = nd_json[1]
                p_dist[p_ind] = [num_type.(nd_json[2])...]
            end
        end
    end
    return parameter_table_all_filtered
end
```

:::


----

### getParameterIndices
```@docs
getParameterIndices
```

:::details Code

```julia
function getParameterIndices(selected_models::LongTuple, parameter_table::Table)
    selected_models_tuple = to_tuple(selected_models)
    return getParameterIndices(selected_models_tuple, parameter_table)
end

function getParameterIndices(selected_models::Tuple, parameter_table::Table)
    r = (;)
    tempvec = Pair{Symbol,Int}[]
    for m in selected_models
        r = (; r..., getModelParameterIndices(m, parameter_table, tempvec)...)
    end
    r
end
```

:::


----

### getParameters
```@docs
getParameters
```

:::details Code

```julia
function getParameters end

function getParameters(selected_models::LongTuple, num_type, model_timestep; return_table=true, show_info=false)
    selected_models = to_tuple(selected_models)
    return getParameters(selected_models, num_type, model_timestep; return_table=return_table, show_info=show_info)
end

function getParameters(selected_models::LongTuple, num_type, model_timestep; return_table=true, show_info=false)
    selected_models = to_tuple(selected_models)
    return getParameters(selected_models, num_type, model_timestep; return_table=return_table, show_info=show_info)
end

function getParameters(selected_models::Tuple, num_type, model_timestep; return_table=true, show_info=false)
    model_names_list = nameof.(typeof.(selected_models))
    constrains = []
    default = []
    name = Symbol[]
    model_approach = Symbol[]
    timescale=String[]
    for obj in selected_models
        k_names = propertynames(obj)
        push!(constrains, SindbadTEM.Processes.bounds(obj)...)
        push!(default, [getproperty(obj, name) for name in k_names]...)
        push!(name, k_names...)
        push!(model_approach, repeat([nameof(typeof(obj))], length(k_names))...)
        push!(timescale, SindbadTEM.Processes.timescale(obj)...)
    end
    # infer types by re-building
    constrains = [c for c in constrains]
    default = [d for d in default]

    nbounds = length(constrains)
    lower = [constrains[i][1] for i in 1:nbounds]
    upper = [constrains[i][2] for i in 1:nbounds]
    
    model = [Symbol(supertype(getproperty(SindbadTEM.Processes, m))) for m in model_approach]
    model_str = string.(model)
    name_full = [join((last(split(model_str[i], ".")), name[i]), ".") for i in 1:nbounds]
    approach_func = [getfield(SindbadTEM.Processes, m) for m in model_approach]
    model_prev = model_approach[1]
    m_id = findall(x-> x==model_prev, model_names_list)[1]
    model_id = map(model_approach) do m
        if m !== model_prev
            model_prev = m
            m_id = findall(x-> x==model_prev, model_names_list)[1]
        end
        m_id
    end

    unts=[]
    unts_ori=[]
    for m in eachindex(name)
        prm_name = Symbol(name[m])
        appr = approach_func[m]()
        p_timescale = SindbadTEM.Processes.timescale(appr, prm_name)
        unit_factor = getUnitConversionForParameter(p_timescale, model_timestep)
        lower[m] = lower[m] * unit_factor
        upper[m] = upper[m] * unit_factor
        if hasproperty(appr, prm_name)
            p_unit = SindbadTEM.Processes.units(appr, prm_name)
            push!(unts_ori, p_unit)
            if ~isone(unit_factor)
                p_unit = replace(p_unit, p_timescale => model_timestep)
            end
            push!(unts, p_unit)
        else
            error("$appr does not have a parameter $prmn")
        end
    end

    # default = num_type.(default)
    lower = map(lower) do low
        if isa(low, Number)
            low = num_type(low)
        else
            low = num_type.(low)
        end
        low
    end
    upper = map(upper) do upp
        if isa(upp, Number)
            upp = num_type(upp)
        else
            upp = num_type.(upp)
        end
        upp
    end
    # lower = num_type.(lower)
    # upper = num_type.(upper)
    timescale_run = map(timescale) do ts
        isempty(ts) ? ts : model_timestep
    end
    checkParameterBounds(name, default, lower, upper, ScaleNone(), p_units=unts, show_info=show_info, model_names=model_approach)
    is_ml = Array{Bool}(undef, length(default))
    dist = Array{String}(undef, length(default))
    p_dist = Array{Array{num_type,1}}(undef, length(default))
    is_ml .= false
    dist .= ""
    p_dist .= [num_type[]]

    output = (; model_id, name, initial=default, default,optimized=default, lower, upper, timescale_run=timescale_run, units=unts, timescale_ori=timescale, units_ori=unts_ori, model, model_approach, approach_func, name_full, is_ml, dist, p_dist)
    output = return_table ? Table(output) : output
    return output
end
```

:::


----

### getSindbadDataDepot
```@docs
getSindbadDataDepot
```

:::details Code

```julia
function getSindbadDataDepot(; env_data_depot_var="SINDBAD_DATA_DEPOT", local_data_depot="../data")
    data_depot = isabspath(local_data_depot) ? local_data_depot : haskey(ENV, env_data_depot_var) ? ENV[env_data_depot_var] : local_data_depot
    return data_depot
end
```

:::


----

### getSpinupSequenceWithTypes
```@docs
getSpinupSequenceWithTypes
```

:::details Code

```julia
function getSpinupSequenceWithTypes(seqq, helpers_dates)
    seqq_typed = []
    for seq in seqq
        for kk in keys(seq)
            if kk == "forcing"
                skip_sampling = false
                if startswith(kk, helpers_dates.temporal_resolution)
                    skip_sampling = true
                end
                aggregator = create_TimeSampler(helpers_dates.range, to_uppercase_first(seq[kk], "Time"), mean, skip_sampling)
                seq["aggregator"] = aggregator
                seq["aggregator_type"] = TimeNoDiff()
                seq["aggregator_indices"] = [_ind for _ind in vcat(aggregator[1].indices...)]
                seq["n_timesteps"] = length(aggregator[1].indices)
                if occursin("_year", seq[kk])
                    seq["aggregator_type"] = TimeIndexed()
                    seq["n_timesteps"] = length(seq["aggregator_indices"])
                end
            end
            if kk == "spinup_mode"
                seq[kk] = getTypeInstanceForNamedOptions(seq[kk])
            end
            if seq[kk] isa String
                seq[kk] = Symbol(seq[kk])
            end
        end
        optns = in(seq, "options") ? seqp["options"] : (;)
        sst = SpinupSequenceWithAggregator(seq["forcing"], seq["n_repeat"], seq["n_timesteps"], seq["spinup_mode"], optns, seq["aggregator_indices"], seq["aggregator"], seq["aggregator_type"]);
        push!(seqq_typed, sst)
    end
    return seqq_typed
end
```

:::


----

### getTypeInstanceForCostMetric
```@docs
getTypeInstanceForCostMetric
```

:::details Code

```julia
function getTypeInstanceForCostMetric(source_module::Module, option_name::String)
    opt_ss = to_uppercase_first(option_name)
    struct_instance = getfield(source_module, opt_ss)()
    return struct_instance
end
```

:::


----

### getTypeInstanceForFlags
```@docs
getTypeInstanceForFlags
```

:::details Code

```julia
function getTypeInstanceForFlags(option_name::Symbol, option_value, opt_pref="Do")
    opt_s = string(option_name)
    structname = to_uppercase_first(opt_s, opt_pref)
    if !option_value
        structname = to_uppercase_first(opt_s, opt_pref*"Not")
    end
    struct_instance = getfield(Setup, structname)()
    return struct_instance
end
```

:::


----

### getTypeInstanceForNamedOptions
```@docs
getTypeInstanceForNamedOptions
```

:::details Code

```julia
function getTypeInstanceForNamedOptions end

function getTypeInstanceForNamedOptions(option_name::String)
    opt_ss = to_uppercase_first(option_name)
    struct_instance = getfield(Setup, opt_ss)()
    return struct_instance
end

function getTypeInstanceForNamedOptions(option_name::String)
    opt_ss = to_uppercase_first(option_name)
    struct_instance = getfield(Setup, opt_ss)()
    return struct_instance
end

function getTypeInstanceForNamedOptions(option_name::Symbol)
    return getTypeInstanceForNamedOptions(string(option_name))
end
```

:::


----

### perturbParameters
```@docs
perturbParameters
```

:::details Code

```julia
function perturbParameters(x::AbstractVector, lower::AbstractVector, upper::AbstractVector; percent_range::Tuple{Float64,Float64}=(0.0, 0.1))
    @assert length(x) == length(lower) == length(upper) "Vectors must have the same length"
    @assert all(lower .<= upper) "Lower bounds must be less than or equal to upper bounds"
    @assert all(lower .<= x .<= upper) "Initial values must be within bounds"
    @assert percent_range[1] >= 0.0 "Minimum percent must be non-negative"
    @assert percent_range[2] >= percent_range[1] "Maximum percent must be greater than or equal to minimum percent"

    min_pct, max_pct = percent_range
    for i in eachindex(x)
        # Generate random percentage within range
        pct = min_pct + rand() * (max_pct - min_pct)
        
        # Calculate new value
        new_val = x[i] * (1 + pct)
        
        # Ensure value stays within bounds
        x[i] = clamp(new_val, lower[i], upper[i])
    end
    return x
end
```

:::


----

### prepCostOptions
```@docs
prepCostOptions
```

:::details Code

```julia
function prepCostOptions end


function prepCostOptions(observations, cost_options)
    return prepCostOptions(observations, cost_options, CostModelObs())
end

function prepCostOptions(observations, cost_options)
    return prepCostOptions(observations, cost_options, CostModelObs())
end

function prepCostOptions(observations, cost_options, ::CostModelObsPriors)
    return prepCostOptions(observations, cost_options, CostModelObs())
end

function prepCostOptions(observations, cost_options, ::CostModelObs)
    valids=[]
    is_valid = []
    vars = cost_options.variable
    obs_inds = cost_options.obs_ind
    min_data_points = cost_options.min_data_points
    for vi in eachindex(vars)
        obs_ind_start = obs_inds[vi]
        min_point = min_data_points[vi]
        y = observations[obs_ind_start]
        yσ = observations[obs_ind_start+1]
        idxs = Array(.!is_invalid_number.(y .* yσ))
        total_point = sum(idxs)
        if total_point < min_point
            push!(is_valid, false)
        else
            push!(is_valid, true)
        end
        push!(valids, idxs)
    end
    cost_options = set_namedtuple_field(cost_options, (:valids, valids))
    cost_options = set_namedtuple_field(cost_options, (:is_valid, is_valid))
    cost_options = drop_namedtuple_fields(cost_options, (:min_data_points, :temporal_data_aggr, :aggr_func,))
    cost_option_table = Table(cost_options)
    cost_options_table_filtered = filter(row -> row.is_valid === true , cost_option_table)
    return cost_options_table_filtered
end
```

:::


----

### readConfiguration
```@docs
readConfiguration
```

:::details Code

```julia
function readConfiguration(info_exp::AbstractDict, base_path::String)
    info = DataStructures.OrderedDict()
    print_info(readConfiguration, @__FILE__, @__LINE__, "reading configuration files")
    for (k, v) ∈ info_exp["experiment"]["basics"]["config_files"]
        config_path = joinpath(base_path, v)
        print_info(nothing, @__FILE__, @__LINE__, "→→→    `$(k)` ::: `$(config_path)`")
        info_exp["experiment"]["basics"]["config_files"][k] = config_path
        if endswith(v, ".json")
            tmp = parsefile(config_path; dicttype=DataStructures.OrderedDict)
            info[k] = removeComments(tmp) # remove on first level
        elseif endswith(v, ".csv")
            prm = CSV.File(config_path)
            tmp = Table(prm)
            info[k] = tmp
        end
    end

    # rm second level
    for (k, v) ∈ info
        if typeof(v) <: Dict
            ks = keys(info[k])
            tmpDict = DataStructures.OrderedDict()
            for ki ∈ ks
                tmpDict[ki] = removeComments(info[k][ki])
            end
            info[k] = tmpDict
        end
    end
    info["experiment"] = info_exp["experiment"]
    return info
end
```

:::


----

### scaleParameters
```@docs
scaleParameters
```

:::details Code

```julia
function scaleParameters end

function scaleParameters(parameter_table, _sc::ScaleNone)
    init = copy(parameter_table.initial)
    ub = copy(parameter_table.upper)  # upper bounds
    lb = copy(parameter_table.lower)   # lower bounds
    checkParameterBounds(parameter_table.name, init, lb, ub, _sc, p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)
    return (init, lb, ub)
end

function scaleParameters(parameter_table, _sc::ScaleNone)
    init = copy(parameter_table.initial)
    ub = copy(parameter_table.upper)  # upper bounds
    lb = copy(parameter_table.lower)   # lower bounds
    checkParameterBounds(parameter_table.name, init, lb, ub, _sc, p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)
    return (init, lb, ub)
end

function scaleParameters(parameter_table, _sc::ScaleDefault)
    init = abs.(copy(parameter_table.initial))
    ub = copy(parameter_table.upper ./ init)   # upper bounds
    lb = copy(parameter_table.lower ./ init)   # lower bounds
    init = parameter_table.initial ./ init
    checkParameterBounds(parameter_table.name, init, lb, ub, _sc, p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)
    return (init, lb, ub)
end

function scaleParameters(parameter_table, _sc::ScaleBounds)
    init = copy(parameter_table.initial)
    ub = copy(parameter_table.upper)  # upper bounds
    lb = copy(parameter_table.lower)   # lower bounds
    init = (init - lb)  ./ (ub - lb)
    lb = zero(lb)
    ub = one.(ub)
    checkParameterBounds(parameter_table.name, init, lb, ub, _sc, p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)
    return (init, lb, ub)
end
```

:::


----

### setHybridInfo
```@docs
setHybridInfo
```

:::details Code

```julia
function setHybridInfo(info::NamedTuple)
    print_info(setHybridInfo, @__FILE__, @__LINE__, "setting info for hybrid machine-learning + TEM experiment...", n_m=1)
    # hybrid_options = info.settings.hybrid
    # set
    info = setHybridOptions(info, :ml_model)
    info = setHybridOptions(info, :ml_training)
    info = setHybridOptions(info, :ml_gradient)
    info = setHybridOptions(info, :ml_optimizer)
    checkpoint_path = ""
    hybrid_root = joinpath(dirname(info.output.dirs.data),"hybrid")
    mkpath(hybrid_root)
    if info.settings.hybrid.save_checkpoint
        checkpoint_path = joinpath(hybrid_root,"training_checkpoints")
        mkpath(checkpoint_path)
    end



    output_dirs = info.temp.output.dirs
    output_dirs = (; output_dirs..., hybrid=(; root=hybrid_root, checkpoint=checkpoint_path))
    info = (; info..., temp = (info.temp..., output = (; info.temp.output..., dirs = output_dirs)))

    fold_type = CalcFoldFromSplit()
    fold_path = ""
    which_fold = 1
    ml_training = info.settings.hybrid.ml_training
    if hasproperty(ml_training, :fold_path)
        fold_path_file = ml_training.fold_path
        fold_path = isnothing(fold_path_file) ? fold_path : fold_path_file
        if !isempty(fold_path)
            fold_type = LoadFoldFromFile()
            if !isabspath(fold_path)
                fold_path = joinpath(info.temp.experiment.dirs.settings, fold_path)
            end
        end
    end
    if hasproperty(ml_training, :which_fold)
        which_fold = ml_training.which_fold
    end

    fold_s = (; fold_path, which_fold, fold_type)
    info = set_namedtuple_subfield(info, :hybrid, (:fold, fold_s))

    replace_value_for_gradient = hasproperty(info.settings.hybrid, :replace_value_for_gradient) ? info.settings.hybrid.replace_value_for_gradient : 0.0

    info = set_namedtuple_subfield(info, :hybrid, (:replace_value_for_gradient, info.temp.helpers.numbers.num_type(replace_value_for_gradient)))

    info = set_namedtuple_subfield(info, :hybrid, (:ml_experiment_type, getTypeInstanceForNamedOptions(info.settings.hybrid.ml_experiment_type)))

    covariates_path = getAbsDataPath(info.temp, info.settings.hybrid.covariates.path)
    covariates = (; path=covariates_path, options=info.settings.hybrid.covariates.options)
    info = set_namedtuple_subfield(info, :hybrid, (:covariates, covariates))
    info = set_namedtuple_subfield(info, :hybrid, (:random_seed, info.settings.hybrid.random_seed))

    return info
end
```

:::


----

### setModelOutput
```@docs
setModelOutput
```

:::details Code

```julia
function setModelOutput(info::NamedTuple)
    print_info(setModelOutput, @__FILE__, @__LINE__, "setting Model Output Info...")
    output_vars = collect(propertynames(info.settings.experiment.model_output.variables))
    info = (; info..., temp=(; info.temp..., output=getDepthInfoAndVariables(info, output_vars)))
    return info
end

function setModelOutputLandAll(info, land)
    output_vars = getAllLandVars(land)
    depth_info = map(output_vars) do v_full_pair
        v_index = findfirst(x -> first(x) === first(v_full_pair) && last(x) === last(v_full_pair), info.output.variables)
        dim_name = nothing
        dim_size = nothing
        if ~isnothing(v_index)
            dim_name = last(info.output.depth_info[v_index])
            dim_size = first(info.output.depth_info[v_index])
        else
            field_name = first(v_full_pair)
            v_name = last(v_full_pair)
            dim_name = string(v_name) * "_idx"
            land_field = getproperty(land, field_name)
            if hasproperty(land_field, v_name)
                land_subfield = getproperty(land_field, v_name)
                if isa(land_subfield, AbstractArray)
                    dim_size = length(land_subfield)
                elseif isa(land_subfield, Number)
                    dim_size = 1
                else
                    dim_size = 0
                end
            end
        end
        dim_size, dim_name
    end
    info = @set info.output.variables = output_vars
    info = @set info.output.depth_info = depth_info
    return info
end
```

:::


----

### setModelOutputLandAll
```@docs
setModelOutputLandAll
```

:::details Code

```julia
function setModelOutputLandAll(info, land)
    output_vars = getAllLandVars(land)
    depth_info = map(output_vars) do v_full_pair
        v_index = findfirst(x -> first(x) === first(v_full_pair) && last(x) === last(v_full_pair), info.output.variables)
        dim_name = nothing
        dim_size = nothing
        if ~isnothing(v_index)
            dim_name = last(info.output.depth_info[v_index])
            dim_size = first(info.output.depth_info[v_index])
        else
            field_name = first(v_full_pair)
            v_name = last(v_full_pair)
            dim_name = string(v_name) * "_idx"
            land_field = getproperty(land, field_name)
            if hasproperty(land_field, v_name)
                land_subfield = getproperty(land_field, v_name)
                if isa(land_subfield, AbstractArray)
                    dim_size = length(land_subfield)
                elseif isa(land_subfield, Number)
                    dim_size = 1
                else
                    dim_size = 0
                end
            end
        end
        dim_size, dim_name
    end
    info = @set info.output.variables = output_vars
    info = @set info.output.depth_info = depth_info
    return info
end
```

:::


----

### setOptimization
```@docs
setOptimization
```

:::details Code

```julia
function setOptimization(info::NamedTuple)
    print_info(setOptimization, @__FILE__, @__LINE__, "setting ParameterOptimization and Observation Info...")
    info = set_namedtuple_field(info, (:optimization, (;)))

    # set information related to cost metrics for each variable
    info = set_namedtuple_subfield(info, :optimization, (:model_parameter_default, info.settings.optimization.model_parameter_default))
    info = set_namedtuple_subfield(info, :optimization, (:observational_constraints, info.settings.optimization.observational_constraints))

    n_threads_cost = 1
    if info.settings.optimization.optimization_cost_threaded > 0 && info.settings.experiment.flags.run_optimization
        n_threads_cost = info.settings.optimization.optimization_cost_threaded > 1 ? info.settings.optimization.optimization_cost_threaded : Threads.nthreads()
        # overwrite land array type when threaded optimization is set
        info = @set info.temp.helpers.run.land_output_type = PreAllocArrayMT()
        # info = set_namedtuple_subfield(info,
        # :optimization,
        # (:n_threads_cost, n_threads_cost))
    end

    # get types for optimization run options
    multi_constraint_method = getTypeInstanceForNamedOptions(info.settings.optimization.multi_constraint_method)
    cost_method = getTypeInstanceForNamedOptions(info.settings.optimization.optimization_cost_method)
    scaling_method = isnothing(info.settings.optimization.optimization_parameter_scaling) ? "scale_none" : info.settings.optimization.optimization_parameter_scaling
    parameter_scaling = getTypeInstanceForNamedOptions(scaling_method)
    optimization_types = (; cost_method, parameter_scaling, multi_constraint_method, n_threads_cost)
    info = set_namedtuple_subfield(info, :optimization, (:run_options, optimization_types))
        
    # check and set the list of parameters to be optimized
    
    # set algorithm related options
    info = setAlgorithmOptions(info, :algorithm_optimization)
    info = setAlgorithmOptions(info, :algorithm_sensitivity_analysis)
    parameter_table = getOptimizationParametersTable(info.temp.models.parameter_table, info.settings.optimization.model_parameter_default, info.settings.optimization.model_parameters_to_optimize)
    
    checkOptimizedParametersInModels(info, parameter_table)

    # use no scaling while checking bounds
    checkParameterBounds(parameter_table.name, parameter_table.initial, parameter_table.lower, parameter_table.upper, ScaleNone(), p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)

    # get the variables to be used during optimization
    obs_vars, optim_vars, store_vars, model_vars = getConstraintNames(info.settings.optimization)
    vars_info = (;)
    vars_info = set_namedtuple_field(vars_info, (:obs, obs_vars))
    vars_info = set_namedtuple_field(vars_info, (:optimization, optim_vars))
    vars_info = set_namedtuple_field(vars_info, (:store, store_vars))
    vars_info = set_namedtuple_field(vars_info, (:model, model_vars))
    info = set_namedtuple_subfield(info, :optimization, (:variables, (vars_info)))
    info = updateVariablesToStore(info)
    cost_options = getCostOptions(info.settings.optimization, vars_info, info.temp.output.variables, info.temp.helpers.numbers, info.temp.helpers.dates)
    info = set_namedtuple_subfield(info, :optimization, (:cost_options, cost_options))
    info = set_namedtuple_subfield(info, :optimization, (:parameter_table, parameter_table))
    optimization_info = info.optimization
    optimization_info = drop_namedtuple_fields(optimization_info, (:model_parameter_default, :model_parameters_to_optimize, :observational_constraints, :variables))
    info = (; info..., optimization = optimization_info)
    return info
end
```

:::


----

### setOrderedSelectedModels
```@docs
setOrderedSelectedModels
```

:::details Code

```julia
function setOrderedSelectedModels(info::NamedTuple)
    print_info(setOrderedSelectedModels, @__FILE__, @__LINE__, "setting Ordered Selected Models...")
    selected_models = collect(propertynames(info.settings.model_structure.models))
    sindbad_models = getAllSindbadModels(info, selected_models=selected_models, selected_models_info=info.settings.model_structure.models)
    checkSelectedModels(sindbad_models, selected_models)
    t_repeat_models = getModelImplicitTRepeat(info, selected_models)
    # checkSelectedModels(sindbad_models, selected_models)
    order_selected_models = []
    for msm ∈ sindbad_models
        if msm in selected_models
            push!(order_selected_models, msm)
        end
    end
    @debug "     setupInfo: creating initial out/land..."

    info = (; info..., temp=(; info.temp..., models=(; sindbad_models=sindbad_models, selected_models=Table((; model=[order_selected_models...],t_repeat=t_repeat_models)))))
    return info
end
```

:::


----

### setPoolsInfo
```@docs
setPoolsInfo
```

:::details Code

```julia
function setPoolsInfo(info::NamedTuple)
    print_info(setPoolsInfo, @__FILE__, @__LINE__, "setting Pools Info...")
    elements = keys(info.settings.model_structure.pools)
    tmp_states = (;)
    hlp_states = (;)
    model_array_type = getfield(Types, to_uppercase_first(info.settings.experiment.exe_rules.model_array_type, "ModelArray"))()
    num_type = info.temp.helpers.numbers.num_type
    for element ∈ elements
        vals_tuple = (;)
        vals_tuple = set_namedtuple_field(vals_tuple, (:zix, (;)))
        vals_tuple = set_namedtuple_field(vals_tuple, (:self, (;)))
        vals_tuple = set_namedtuple_field(vals_tuple, (:all_components, (;)))
        elSymbol = Symbol(element)
        tmp_elem = (;)
        hlp_elem = (;)
        tmp_states = set_namedtuple_field(tmp_states, (elSymbol, (;)))
        hlp_states = set_namedtuple_field(hlp_states, (elSymbol, (;)))
        pool_info = getfield(getfield(info.settings.model_structure.pools, element), :components)
        nlayers = Int64[]
        layer_thicknesses = num_type[]
        layer = Int64[]
        inits = []
        sub_pool_name = Symbol[]
        main_pool_name = Symbol[]
        main_pools = Symbol.(keys(getfield(getfield(info.settings.model_structure.pools, element), :components)))
        layer_thicknesses, nlayers, layer, inits, sub_pool_name, main_pool_name = getPoolInformation(main_pools, pool_info, layer_thicknesses, nlayers, layer, inits, sub_pool_name, main_pool_name)

        # set empty tuple fields
        tpl_fields = (:components, :zix, :initial_values, :layer_thickness)
        for _tpl ∈ tpl_fields
            tmp_elem = set_namedtuple_field(tmp_elem, (_tpl, (;)))
        end
        hlp_elem = set_namedtuple_field(hlp_elem, (:layer_thickness, (;)))
        # hlp_elem = set_namedtuple_field(hlp_elem, (:n_layers, (;)))
        hlp_elem = set_namedtuple_field(hlp_elem, (:zix, (;)))
        hlp_elem = set_namedtuple_field(hlp_elem, (:components, (;)))
        hlp_elem = set_namedtuple_field(hlp_elem, (:all_components, (;)))
        hlp_elem = set_namedtuple_field(hlp_elem, (:zeros, (;)))
        hlp_elem = set_namedtuple_field(hlp_elem, (:ones, (;)))

        # main pools
        for main_pool ∈ main_pool_name
            zix = Int[]
            initial_values = []
            # initial_values = num_type[]
            components = Symbol[]
            for (ind, par) ∈ enumerate(sub_pool_name)
                if startswith(String(par), String(main_pool))
                    push!(zix, ind)
                    push!(components, sub_pool_name[ind])
                    push!(initial_values, inits[ind])
                end
            end
            initial_values = createArrayofType(initial_values, Nothing[], num_type, nothing, true, model_array_type)

            zix = Tuple(zix)

            tmp_elem = set_namedtuple_subfield(tmp_elem, :components, (main_pool, Tuple(components)))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :zix, (main_pool, zix))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :initial_values, (main_pool, initial_values))
            # hlp_elem = set_namedtuple_subfield(hlp_elem, :n_layers, (main_pool, length(zix)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zix, (main_pool, zix))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :components, (main_pool, Tuple(components)))
            onetyped = createArrayofType(ones(size(initial_values)), Nothing[], num_type, nothing, true, model_array_type)
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zeros, (main_pool, zero(onetyped)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :ones, (main_pool, onetyped))
        end

        # subpools
        unique_sub_pools = Symbol[]
        for _sp ∈ sub_pool_name
            if _sp ∉ unique_sub_pools
                push!(unique_sub_pools, _sp)
            end
        end
        for sub_pool ∈ unique_sub_pools
            zix = Int[]
            initial_values = []
            components = Symbol[]
            ltck = num_type[]
            # ltck = []
            for (ind, par) ∈ enumerate(sub_pool_name)
                if par == sub_pool
                    push!(zix, ind)
                    push!(initial_values, inits[ind])
                    push!(components, sub_pool_name[ind])
                    push!(ltck, layer_thicknesses[ind])
                end
            end
            zix = Tuple(zix)
            initial_values = createArrayofType(initial_values, Nothing[], num_type, nothing, true, model_array_type)
            tmp_elem = set_namedtuple_subfield(tmp_elem, :components, (sub_pool, Tuple(components)))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :zix, (sub_pool, zix))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :initial_values, (sub_pool, initial_values))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :layer_thickness, (sub_pool, Tuple(ltck)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :layer_thickness, (sub_pool, Tuple(ltck)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zix, (sub_pool, zix))
            # hlp_elem = set_namedtuple_subfield(hlp_elem, :n_layers, (sub_pool, length(zix)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :components, (sub_pool, Tuple(components)))
            onetyped = createArrayofType(ones(size(initial_values)), Nothing[], num_type, nothing, true, model_array_type)
            # onetyped = ones(length(initial_values))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zeros, (sub_pool, zero(onetyped)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :ones, (sub_pool, onetyped))
        end

        ## combined pools
        combine_pools = (getfield(getfield(info.settings.model_structure.pools, element), :combine))
        do_combine = true
        tmp_elem = set_namedtuple_field(tmp_elem, (:combine, (; docombine=true, pool=Symbol(combine_pools))))
        if do_combine
            combined_pool_name = Symbol.(combine_pools)
            create = Symbol[combined_pool_name]
            components = Symbol[]
            for _sp ∈ sub_pool_name
                if _sp ∉ components
                    push!(components, _sp)
                end
            end
            initial_values = inits
            initial_values = createArrayofType(initial_values, Nothing[], num_type, nothing, true, model_array_type)
            zix = collect(1:1:length(main_pool_name))
            zix = Tuple(zix)

            tmp_elem = set_namedtuple_subfield(tmp_elem, :components, (combined_pool_name, Tuple(components)))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :zix, (combined_pool_name, zix))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :initial_values, (combined_pool_name, initial_values))
            # hlp_elem = set_namedtuple_subfield(hlp_elem, :n_layers, (combined_pool_name, length(zix)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zix, (combined_pool_name, zix))
            onetyped = createArrayofType(ones(size(initial_values)), Nothing[], num_type, nothing, true, model_array_type)
            all_components = Tuple([_k for _k in keys(tmp_elem.zix) if _k !== combined_pool_name])
            hlp_elem = set_namedtuple_subfield(hlp_elem, :all_components, (combined_pool_name, all_components))
            vals_tuple = set_namedtuple_subfield(vals_tuple, :zix, (combined_pool_name, Val(hlp_elem.zix)))
            vals_tuple = set_namedtuple_subfield(vals_tuple, :self, (combined_pool_name, Val(combined_pool_name)))
            vals_tuple = set_namedtuple_subfield(vals_tuple, :all_components, (combined_pool_name, Val(all_components)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :components, (combined_pool_name, Tuple(components)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zeros, (combined_pool_name, zero(onetyped)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :ones, (combined_pool_name, onetyped))
        else
            create = Symbol.(unique_sub_pools)
        end

        # check if additional variables exist
        if hasproperty(getfield(info.settings.model_structure.pools, element), :state_variables)
            state_variables = getfield(getfield(info.settings.model_structure.pools, element), :state_variables)
            tmp_elem = set_namedtuple_field(tmp_elem, (:state_variables, state_variables))
        end
        arraytype = :view
        if hasproperty(info.settings.experiment.exe_rules, :model_array_type)
            arraytype = Symbol(info.settings.experiment.exe_rules.model_array_type)
        end
        tmp_elem = set_namedtuple_field(tmp_elem, (:arraytype, arraytype))
        tmp_elem = set_namedtuple_field(tmp_elem, (:create, create))
        tmp_states = set_namedtuple_field(tmp_states, (elSymbol, tmp_elem))
        hlp_states = set_namedtuple_field(hlp_states, (elSymbol, hlp_elem))
    end
    hlp_new = (;)
    # tc_print(hlp_states)
    eleprops = propertynames(hlp_states)
    if :carbon in eleprops && :water in eleprops
        for prop ∈ propertynames(hlp_states.carbon)
            cfield = getproperty(hlp_states.carbon, prop)
            wfield = getproperty(hlp_states.water, prop)
            cwfield = (; cfield..., wfield...)
            if prop == :vals
                cwfield = (;)
                for subprop in propertynames(cfield)
                    csub = getproperty(cfield, subprop)
                    wsub = getproperty(wfield, subprop)
                    cwfield = set_namedtuple_field(cwfield, (subprop, (; csub..., wsub...)))
                end
            end
            hlp_new = set_namedtuple_field(hlp_new, (prop, cwfield))
        end
    elseif :carbon in eleprops && :water ∉ eleprops
        hlp_new = hlp_states.carbon
    elseif :carbon ∉ eleprops && :water in eleprops
        hlp_new = hlp_states.water
    else
        hlp_new = hlp_states
    end

    # get the number of layers per pool 
    n_layers = NamedTuple(map(propertynames(hlp_new.ones)) do one_pool
        n_pool = num_type(length(getproperty(hlp_new.ones, one_pool)))
        Pair(one_pool, n_pool)
    end
    )
    hlp_new = (hlp_new..., n_layers=n_layers)

    info = (; info..., pools=tmp_states, temp=(; info.temp..., helpers=(; info.temp.helpers..., pools=hlp_new)))
    return info
end
```

:::


----

### setSpinupAndForwardModels
```@docs
setSpinupAndForwardModels
```

:::details Code

```julia
function setSpinupAndForwardModels(info::NamedTuple)
    print_info(setSpinupAndForwardModels, @__FILE__, @__LINE__, "setting Spinup and Forward Models...")
    selected_approach_forward = ()
    is_spinup = Int64[]
    order_selected_models = info.temp.models.selected_models.model
    default_model = getfield(info.settings.model_structure, :default_model)
    for sm ∈ order_selected_models
        model_info = getfield(info.settings.model_structure.models, sm)
        selected_approach = model_info.approach
        selected_approach = String(sm) * "_" * selected_approach
        selected_approach_func = getTypedModel(Symbol(selected_approach), info.temp.helpers.dates.temporal_resolution, info.temp.helpers.numbers.num_type)
        selected_approach_forward = (selected_approach_forward..., selected_approach_func)
        if :use_in_spinup in propertynames(model_info)
            use_in_spinup = model_info.use_in_spinup
        else
            use_in_spinup = default_model.use_in_spinup
        end
        if use_in_spinup == true
            push!(is_spinup, 1)
        else
            push!(is_spinup, 0)
        end
    end
    # change is_spinup to a vector of indices
    is_spinup = findall(is_spinup .== 1)

    # update the parameters of the approaches if a parameter value has been added from the experiment configuration
    default_parameter_table = getParameters(selected_approach_forward, info.temp.helpers.numbers.num_type, info.temp.helpers.dates.temporal_resolution)

    input_parameter_table = nothing
    if hasproperty(info.settings.model_structure, :parameter_table) && !isempty(info.settings.model_structure.parameter_table)
        print_info(setSpinupAndForwardModels, @__FILE__, @__LINE__, "---using input parameters from model_structure.parameter_table in replace_info", n_m=20)

        input_parameter_table = info.settings.model_structure.parameter_table
    elseif hasproperty(info[:settings], :parameters) && !isempty(info.settings.parameters)
        print_info(setSpinupAndForwardModels, @__FILE__, @__LINE__, "     ---using input parameters from settings.parameters passed from CSV input file", n_m=20)
        input_parameter_table = info.settings.parameters
    end
    updated_parameter_table = copy(default_parameter_table)
    if !isnothing(input_parameter_table)
        if !isa(input_parameter_table, Table)
            error("input_parameter_table must be a Table, but its type is $(typeof(input_parameter_table)). Fix the input error in the source (table or csv file) to continue...")
        end
        updated_parameter_table = setInputParameters(default_parameter_table, input_parameter_table, info.temp.helpers.dates.temporal_resolution)
        selected_approach_forward = updateModelParameters(updated_parameter_table, selected_approach_forward, updated_parameter_table.optimized)
    end
    info = (; info..., temp=(; info.temp..., models=(; info.temp.models..., forward=selected_approach_forward, is_spinup=is_spinup, parameter_table=updated_parameter_table))) 
    return info
end
```

:::


----

### setupInfo
```@docs
setupInfo
```

:::details Code

```julia
function setupInfo(info::NamedTuple)
    print_info(setupInfo, @__FILE__, @__LINE__, "Setting and consolidating Experiment Info...")
    # @show info.settings.model_structure.parameter_table.optimized
    info = setExperimentBasics(info)
    # @info "  setupInfo: setting Output Basics..."
    info = setExperimentOutput(info)
    # @info "  setupInfo: setting Numeric Helpers..."
    info = setNumericHelpers(info)
    # @info "  setupInfo: setting Pools Info..."
    info = setPoolsInfo(info)
    # @info "  setupInfo: setting Dates Helpers..."
    info = setDatesInfo(info)
    # @info "  setupInfo: setting Model Structure..."
    info = setOrderedSelectedModels(info)
    # @info "  setupInfo: setting Spinup and Forward Models..."
    info = setSpinupAndForwardModels(info)

    # @info "  setupInfo:         ...saving Selected Models Code..."
    _ = parseSaveCode(info)

    # add information related to model run
    # @info "  setupInfo: setting Model Run Flags..."
    info = setModelRunInfo(info)
    # @info "  setupInfo: setting Spinup Info..."
    info = setSpinupInfo(info)

    # @info "  setupInfo: setting Model Output Info..."
    info = setModelOutput(info)

    # @info "  setupInfo: creating Initial Land..."
    land_init = createInitLand(info.pools, info.temp)
    info = (; info..., temp=(; info.temp..., helpers=(; info.temp.helpers..., land_init=land_init)))

    if (info.settings.experiment.flags.run_optimization || info.settings.experiment.flags.calc_cost) && hasproperty(info.settings.optimization, :algorithm_optimization)
        # @info "  setupInfo: setting ParameterOptimization and Observation info..."
        info = setOptimization(info)
    else
        parameter_table = info.temp.models.parameter_table
        checkParameterBounds(parameter_table.name, parameter_table.initial, parameter_table.lower, parameter_table.upper, ScaleNone(), p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)
     end

    if hasproperty(info.settings, :hybrid)
        info = setHybridInfo(info)
    end

    if !isnothing(info.settings.experiment.exe_rules.longtuple_size)
        selected_approach_forward = to_longtuple(info.temp.models.forward, info.settings.experiment.exe_rules.longtuple_size)
        info = @set info.temp.models.forward = selected_approach_forward
    end

    print_info(setupInfo, @__FILE__, @__LINE__, "Cleaning Info Fields...")
    data_settings = (; forcing = info.settings.forcing, optimization = info.settings.optimization)
    exe_rules = info.settings.experiment.exe_rules
    info = drop_namedtuple_fields(info, (:model_structure, :experiment, :output, :pools))
    info = (; info..., info.temp...)
    info = set_namedtuple_subfield(info, :experiment, (:data_settings, data_settings))
    info = set_namedtuple_subfield(info, :experiment, (:exe_rules, exe_rules))
    info = drop_namedtuple_fields(info, (:temp, :settings,))
    return info
end
```

:::


----

### sindbadDefaultOptions
```@docs
sindbadDefaultOptions
```

:::details Code

```julia
function sindbadDefaultOptions end
# A basic empty options for all SindbadTypes
sindbadDefaultOptions(::SindbadTypes) = (;)

sindbadDefaultOptions(::CMAEvolutionStrategyCMAES) = (; maxfevals = 50)

sindbadDefaultOptions(::GSAMorris) = (; total_num_trajectory = 200, num_trajectory = 15, len_design_mat=10)

sindbadDefaultOptions(::GSASobol) = (; samples = 5, method_options=(; order=[0, 1]), sampler="Sobol", sampler_options=(;))

sindbadDefaultOptions(::GSASobolDM) = sindbadDefaultOptions(GSASobol())

```

:::


----

### updateModelParameters
```@docs
updateModelParameters
```

:::details Code

```julia
function updateModelParameters end

function updateModelParameters(parameter_table::Table, selected_models::LongTuple, parameter_vector::AbstractArray)
    selected_models = to_tuple(selected_models)
    return updateModelParameters(parameter_table, selected_models, parameter_vector)
end

function updateModelParameters(parameter_table::Table, selected_models::LongTuple, parameter_vector::AbstractArray)
    selected_models = to_tuple(selected_models)
    return updateModelParameters(parameter_table, selected_models, parameter_vector)
end

function updateModelParameters(parameter_table::Table, selected_models::Tuple, parameter_vector::AbstractArray)
    updatedModels = eltype(selected_models)[]
    namesApproaches = nameof.(typeof.(selected_models)) # a better way to do this?
    for (idx, modelName) ∈ enumerate(namesApproaches)
        approachx = selected_models[idx]
        model_obj = approachx
        newapproachx = if modelName in parameter_table.model_approach
            vars = propertynames(approachx)
            newvals = Pair[]
            for var ∈ vars
                pindex = findall(row -> row.name == var && row.model_approach == modelName,
                    parameter_table)
                pval = getproperty(approachx, var)
                if !isempty(pindex)
                    pval = parameter_vector[pindex[1]]
                end
                push!(newvals, var => pval)
            end
            typeof(approachx)(; newvals...)
        else
            approachx
        end
        push!(updatedModels, newapproachx)
    end
    return (updatedModels...,)
end

function updateModelParameters(parameter_to_index::NamedTuple, selected_models, parameter_vector::AbstractArray)
    map(selected_models) do model
          modelmap = parameter_to_index[nameof(typeof(model))]
          varsreplace = map(i->parameter_vector[i],modelmap)
          ConstructionBase.setproperties(model,varsreplace)
    end
end
```

:::


----

### updateModels
```@docs
updateModels
```

:::details Code

```julia
function updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    parameter_vector = backScaleParameters(parameter_vector, parameter_updater, parameter_scaling_type)
    updated_models = updateModelParameters(parameter_updater, selected_models, parameter_vector)
    return updated_models
end
```

:::


----

### updateVariablesToStore
```@docs
updateVariablesToStore
```

:::details Code

```julia
function updateVariablesToStore(info::NamedTuple)
    output_vars = info.settings.experiment.model_output.variables
    if info.settings.experiment.flags.calc_cost || !info.settings.optimization.subset_model_output
        output_vars = union(String.(keys(output_vars)),
                info.optimization.variables.model)
    else
        output_vars = map(info.optimization.variables.obs) do vo
            vn = getfield(info.optimization.variables.optimization, vo)
            Symbol(string(vn[1]) * "." * string(vn[2]))
        end        
    end
    info = (; info..., temp=(; info.temp..., output=getDepthInfoAndVariables(info, output_vars)))
    return info
end
```

:::


----

```@meta
CollapsedDocStrings = false
DocTestSetup= quote
using Sindbad.Setup
end
```
