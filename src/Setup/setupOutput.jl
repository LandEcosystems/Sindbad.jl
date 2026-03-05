export getDepthDimensionSizeName
export getDepthInfoAndVariables
export setModelOutput
export setModelOutputLandAll
export updateVariablesToStore


"""
    getAllLandVars(land)

Collects model variable fields and subfields from the `land` NamedTuple.

# Arguments:
- `land`: A core SINDBAD NamedTuple containing all variables for a given time step, overwritten at every timestep.

# Returns:
- A tuple of variable field and subfield pairs.
"""
function getAllLandVars(land)
    av=[]
    for f in propertynames(land)
        lf = getproperty(land,f)
        for sf in propertynames(lf)
            pv = getproperty(lf, sf)
            if (isa(pv, AbstractArray) && ndims(pv) < 2)  || isa(pv, Number)
                push!(av, (f, sf))
            end
        end
    end
    return Tuple(av)
end

"""
    getDepthDimensionSizeName(vname::Symbol, info::NamedTuple)

Retrieves the name and size of the depth dimension for a given variable.

# Arguments:
- `vname`: The variable name.
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.

# Returns:
- A tuple containing the size and name of the depth dimension.

# Notes:
- Validates the depth dimension against the `depth_dimensions` field in the experiment configuration.
"""
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


"""
    getDepthInfoAndVariables(info, output_vars)

Generates depth information and variable pairs for the output variables.

# Arguments:
- `info`: A SINDBAD NamedTuple containing experiment configuration.
- `output_vars`: A list of output variables.

# Returns:
- A NamedTuple containing depth information and variable pairs.
"""
function getDepthInfoAndVariables(info, output_vars)
    out_vars_pairs = Tuple(getVariablePair.(output_vars))
    depth_info = map(out_vars_pairs) do vname_full
        getDepthDimensionSizeName(vname_full, info)
    end
    output_info=(; info.output..., depth_info, variables=out_vars_pairs)
    return output_info
end


"""
    getPoolSize(info_pools::NamedTuple, pool_name::Symbol)

Retrieves the size of a pool variable from the model structure settings.

# Arguments:
- `info_pools`: A NamedTuple containing information about the pools in the selected model structure.
- `pool_name`: The name of the pool.

# Returns:
- The size of the specified pool.

# Notes:
- Throws an error if the pool does not exist in the model structure.
"""
function getPoolSize(info_pools::NamedTuple, pool_name::Symbol)
    poolsize = nothing
    for elem ∈ keys(info_pools)
        zixelem = getfield(info_pools, elem)
        if pool_name in keys(zixelem)
            return length(getfield(zixelem, pool_name))
        end
    end
    if isnothing(poolsize)
        error(
            "The output depth_dimensions $(pool_name) does not exist in the selected model structure. Either add the pool to model_structure.json or adjust depth_dimensions or output variables in model_run.json."
        )
    end
end

"""
    getOrderedOutputList(varlist, var_o::Symbol)

Finds and returns the corresponding variable from the full list of variables.

# Arguments:
- `varlist`: The full list of variables.
- `var_o`: The variable to find.

# Returns:
- The corresponding variable from the list.
"""
function getOrderedOutputList(varlist, var_o::Symbol)
    for var ∈ varlist
        vname = Symbol(split(string(var), '.')[end])
        if vname === var_o
            return var
        end
    end
end


"""
    getVariableGroups(var_list::AbstractArray)

Groups variables into a NamedTuple based on their field and subfield structure.

# Arguments:
- `var_list`: A list of variables in the `field.subfield` format.

# Returns:
- A NamedTuple containing grouped variables by field.
"""
function getVariableGroups(var_list::AbstractArray)
    var_dict = Dict()
    for var ∈ var_list
        var_l = String(var)
        vf = split(var_l, ".")[1]
        vvar = split(var_l, ".")[2]
        if vf ∉ keys(var_dict)
            var_dict[vf] = []
            push!(var_dict[vf], vvar)
        else
            push!(var_dict[vf], vvar)
        end
    end
    varNT = (;)
    for (k, v) ∈ var_dict
        varNT = set_namedtuple_field(varNT, (Symbol(k), tuple(Symbol.(v)...)))
    end
    return varNT
end


"""
    getVariablePair(out_var)

Splits a variable name into a pair of field and subfield.

# Arguments:
- `out_var`: The variable name, provided as either a `String` or a `Symbol`, in the format `field.subfield`.

# Returns:
- A tuple containing the field and subfield as `Symbol` values.

# Notes:
- If the variable name contains a comma (`,`), it is used as the separator instead of a dot (`.`).
- This function is used to parse variable names into their hierarchical components for further processing.
"""
function getVariablePair end

function getVariablePair(out_var::String)
    sep = "."
    if occursin(",", out_var)
        sep = ","
    end
    return Tuple(Symbol.(split(string(out_var), sep)))
end

function getVariablePair(out_var::Symbol)
    getVariablePair(string(out_var))
end



"""
    getVariableString(var_pair)

Converts a variable pair into a string representation.

# Arguments:
- `var_pair`: A tuple containing the field and subfield.
- `sep`: The separator to use between the field and subfield (default: ".").

# Returns:
- A string representation of the variable pair.
"""
function getVariableString(var_pair::Tuple, sep=".")
    return string(first(var_pair)) * sep * string(last(var_pair))
end


"""
    saveExperimentSettings(info)

Saves a copy of the experiment settings to the output folder.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Notes:
- Copies the JSON settings and configuration files to the output directory.
"""
function saveExperimentSettings(info)
    sindbad_experiment = info.temp.experiment.dirs.sindbad_experiment
    print_info(saveExperimentSettings, @__FILE__, @__LINE__, "saving Experiment JSON Settings to : $(info.output.dirs.settings)")
    cp(sindbad_experiment,
        joinpath(info.output.dirs.settings, split(sindbad_experiment, path_separator)[end]);
        force=true)
    for k ∈ keys(info.settings.experiment.basics.config_files)
        v = getfield(info.settings.experiment.basics.config_files, k)
        cp(v, joinpath(info.output.dirs.settings, split(v, path_separator)[end]); force=true)
    end
end

"""
    setExperimentOutput(info)

Sets up and creates the output directory for the experiment.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with output directory information added.

# Notes:
- Creates subdirectories for code, data, figures, and settings.
- Validates the output path and ensures it is not within the SINDBAD root directory.
"""
function setExperimentOutput(info)
    print_info(setExperimentOutput, @__FILE__, @__LINE__, "setting Experiment Output Paths...")
    path_output = info[:settings][:experiment][:model_output][:path]
    dir_base = info.temp.experiment.dirs.experiment

    # path_input is your variable

    # 1. Handle nothing or empty or "." or "./"
    if path_output === nothing || path_output == "" || path_output == "." || path_output == "./"
        path_resolved = dir_base

    # 2. Absolute path → use as-is
    elseif isabspath(path_output)
        path_resolved = path_output

    # 3. Relative path → prepend working directory
    else
        path_resolved = joinpath(dir_base, path_output)
    end

    path_resolved_normalized = normalize_path_separator(path_resolved)
    last_dir = "output_"*info.temp.experiment.basics.id
    path_output_full = joinpath(path_resolved_normalized, last_dir)

    # create output and subdirectories
    sub_output = ["code", "data", "figure", "root", "settings"]
    if info.settings.experiment.flags.run_optimization || info.settings.experiment.flags.calc_cost
        push!(sub_output, "optimization")
    end
    out_info = (; dirs=(;), format=info.settings.experiment.model_output.format)
    for s_o ∈ sub_output
        if s_o == "root"
            out_info = set_namedtuple_subfield(out_info, :dirs, (Symbol(s_o), path_output_full))
        else
            out_info = set_namedtuple_subfield(out_info, :dirs,
                (Symbol(s_o), joinpath(path_output_full, s_o)))
            mkpath(getfield(getfield(out_info, :dirs), Symbol(s_o)))
        end
    end
    global_metadata = getGlobalAttributesForOutCubes(info)
    file_prefix = joinpath(out_info.dirs.data, info.temp.experiment.basics.name * "_" * info.temp.experiment.basics.domain)
    out_file_info = (; global_metadata=global_metadata, file_prefix=file_prefix)
    out_info = (; out_info..., file_info=out_file_info)  
    info = set_namedtuple_field(info, (:output, out_info))
    print_info(nothing, @__FILE__, @__LINE__, "→→→    output directory set to: `$(info.output.dirs.root)`")
    saveExperimentSettings(info)
    return info
end

"""
    setModelOutput(info::NamedTuple)

Sets the output variables to be written and stored based on the experiment configuration.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with output variables and depth information added.
"""
function setModelOutput(info::NamedTuple)
    print_info(setModelOutput, @__FILE__, @__LINE__, "setting Model Output Info...")
    output_vars = collect(propertynames(info.settings.experiment.model_output.variables))
    info = (; info..., temp=(; info.temp..., output=getDepthInfoAndVariables(info, output_vars)))
    return info
end


"""
    setModelOutputLandAll(info, land)

Retrieves all model variables from `land` and overwrites the output information in `info`.

# Arguments:
- `info`: A NamedTuple containing experiment configuration and helper information.
- `land`: A core SINDBAD NamedTuple containing variables for a given time step.

# Returns:
- The updated `info` NamedTuple with output variables and depth information updated.
"""
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

"""
    updateVariablesToStore(info::NamedTuple)

Updates the output variables to store based on optimization or cost run settings.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with updated output variables.
"""
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
