export getOptimizationParametersTable
export filterParameterTable
export getParameters
export getParameterIndices
export perturbParameters


"""
    filterParameterTable(parameter_table::Table; prop_name::Symbol=:model, prop_values::Tuple{Symbol}=(:all,))

Filters a parameter table based on a specified property and values.

# Arguments
- `parameter_table::Table`: The parameter table to filter
- `prop_name::Symbol`: The property to filter by (default: :model)
- `prop_values::Tuple{Symbol}`: The values to filter by (default: :all)

# Returns
A filtered parameter table.

# Examples
```jldoctest
julia> using Sindbad

julia> # Filter parameter table by model
julia> # filtered_table = filterParameterTable(parameter_table; prop_name=:model, prop_values=(:gpp,))

julia> # Return all parameters
julia> # all_params = filterParameterTable(parameter_table; prop_values=:all)
```
"""
function filterParameterTable(parameter_table::Table; prop_name::Symbol=:model, prop_values::Union{Vector{Symbol},Symbol}=:all)
    if prop_values == :all
        return parameter_table
    elseif isa(prop_values, Symbol)
        return filter(row -> getproperty(row, prop_name) == prop_values, parameter_table)
    else
        return filter(row -> getproperty(row, prop_name) in prop_values, parameter_table)
    end
end

"""
    getParameters(selected_models::Tuple, num_type, model_timestep; return_table=true)
    getParameters(selected_models::LongTuple, num_type, model_timestep; return_table=true)
Retrieves parameters for the specified models with given numerical type and timestep settings. 

# Arguments
- `selected_models`: A collection of selected models
    - `::Tuple`: as a tuple 
    - `::LongTuple`: as a long tuple
- `num_type`: The numerical type to be used for parameters
- `model_timestep`: The timestep setting for the model simulation
- `return_table::Bool=true`: Whether to return results in table format

# Returns
Parameters information for the selected models based on the specified settings.

# Examples
```jldoctest
julia> using Sindbad

julia> # Get parameters for selected models
julia> # param_table = getParameters(selected_models, Float64, model_timestep)
```
"""
function getParameters end

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
function getParameters(model::LandEcosystem)
    k_names = propertynames(model)
    bounds  = SindbadTEM.Processes.bounds(model)

    params = map(k_names, bounds, SindbadTEM.Processes.timescale(model)) do n, b, ts
        n => (default = getproperty(model, n),
            lower = first(b),
            upper = last(b),
            units = SindbadTEM.Processes.units(model, n),
            timescale = ts)
    end

    return NamedTuple(params)
end

function Base.show(io::IO, ::MIME"text/plain", params::NamedTuple)
    isempty(params) && return show(io, params)

    all(v -> v isa NamedTuple{(:default, :lower, :upper, :units, :timescale)},
        values(params)) || return show(io, params)

    K = keys(params)
    pad = maximum(length ∘ string, K) + 2

    printstyled(io, "NamedTuple:", color=:light_black)
    printstyled(io, " Parameters ($(length(K)))\n", color=:cyan)
    printstyled(io, "─"^(pad + 12) * "\n", color=:light_black)

    for k in K
        p = params[k]

        ts = isempty(p.timescale) ? "—" : p.timescale
        u  = isempty(p.units)     ? "—" : p.units

        printstyled(io, "  $(rpad(k, pad))", color=:yellow)
        printstyled(io, " default: ") # color=:light_black
        printstyled(io, _preview(p.default), color=:white, bold=true)
        println(io)

        printstyled(io, "  $(rpad("", pad))  bounds: ", color=:light_black)
        printstyled(io, _preview((p.lower, p.upper)), color=:green)
        println(io)

        printstyled(io, "  $(rpad("", pad))   units: ", color=:magenta)
        printstyled(io, u)
        println(io)

        printstyled(io, "$(rpad("", pad)) timescale: ", color=:blue)
        printstyled(io, ts)
        println(io)
    end
end

function _preview(x; max_elems=5)
    io = IOBuffer()
    _preview(io, x, max_elems)
    return String(take!(io))
end

function _preview(io::IO, x::AbstractArray, max_elems)
    print(io, typeof(x), "(", size(x), ") ")

    flat = vec(x)
    n = length(flat)

    if n <= max_elems
        print(io, flat)
    else
        print(io, "[")

        half = max_elems ÷ 2

        for i in 1:half
            print(io, flat[i], ", ")
        end

        print(io, " … ")

        for i in (n - half + 1):n
            print(io, flat[i])
            if i != n
                print(io, ", ")
            end
        end

        print(io, "]")
    end
end

function _preview(io::IO, x::Tuple, max_elems)
    print(io, "(")

    for (i, v) in enumerate(x)
        _preview(io, v, max_elems÷3)
        i != length(x) && print(io, ", ")
    end

    print(io, ")")
end

function _preview(io::IO, x, max_elems)
    print(io, x)
end

"""
    getOptimizationParametersTable(parameter_table_all::Table, model_parameter_default, optimization_parameters)

Creates a filtered and enhanced parameter table for optimization by combining input parameters with default model parameters with the table of all parameters in the selected model structure.

# Arguments
- `parameter_table_all::Table`: A table containing all model parameters
- `model_parameter_default`: Default parameter settings including distribution and a flag differentiating if the parameter is to be ML-parameter-learnt
- `optimization_parameters`: Parameters to be optimized, specified either as:
    - `::NamedTuple`: Named tuple with parameter configurations
    - `::Vector`: Vector of parameter names to use with default settings

# Returns
A filtered `Table` containing only the optimization parameters, enhanced with:
- `is_ml`: Boolean flag indicating if parameter uses machine learning
- `dist`: Distribution type for each parameter
- `p_dist`: Distribution parameters as an array of numeric values

# Notes
- Parameters can be specified using comma-separated strings for model.parameter pairs
- For NamedTuple inputs, individual parameter configurations override model_parameter_default
- The output table preserves the numeric type of the input parameters
"""
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


"""
    getModelParameterIndices(model, parameter_table::Table, r)

Retrieves indices for model parameters from a parameter table.

# Arguments

- `model`: A model object for which parameters are being indexed
- `parameter_table::Table`: Table containing parameter information
- `r`: Row index or identifier for the specific parameter set

# Returns
Indices corresponding to the model parameters in the parameter table for a model.
"""
function getModelParameterIndices(model, parameter_table::Table, r)
    modelName = nameof(typeof(model))
    empty!(r)
    for var in propertynames(model)

        pindex = findfirst(row -> row.name == var && row.model_approach == modelName, parameter_table)
        if !isnothing(pindex)
            push!(r, var => pindex)
        end
    end
    NamedTuple((modelName => NamedTuple(r),))
end


"""
    getParameterIndices(selected_models::LongTuple, parameter_table::Table)
    getParameterIndices(selected_models::Tuple, parameter_table::Table)

Retrieves indices for model parameters from a parameter table.

# Arguments
- `selected_models`
    - `::LongTuple`: A long tuple of selected models
    - `::Tuple`: A tuple of selected models
- `parameter_table::Table`: Table containing parameter information

# Returns
A Tuple of Pair of Name and Indices corresponding to the model parameters in the parameter table for  selected models.
"""
function getModelParameterIndices end

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



"""
    perturbParameters(x::AbstractVector, lower::AbstractVector, upper::AbstractVector, percent_range::Tuple{Float64,Float64}=(0.0, 0.1))

Modify each element of vector `x` by a random percentage within `percent_range`, while ensuring the result stays within the bounds defined by `lower` and `upper` vectors.

# Arguments
- `x`: Vector to modify
- `lower`: Vector of lower bounds
- `upper`: Vector of upper bounds
- `percent_range`: Tuple of (min_percent, max_percent) for random modification (default: (0.0, 0.1))

# Returns
- Modified vector `x` (modified in-place)

# Example
```julia
x = [1.0, 2.0, 3.0]
lower = [0.5, 1.5, 2.5]
upper = [1.5, 2.5, 3.5]
modify_within_bounds!(x, lower, upper, (0.0, 0.1))  # Modify by 0-10%
```
"""
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


"""
    replaceCommaSeparatedParams(p_names_list)

get a list/vector of parameters in which each parameter string is split with comma to separate model name and parameter name
"""
function replaceCommaSeparatedParams(p_names_list)
    o_p_names_list = []
    foreach(p_names_list) do p
        p_name = splitRenameParam(p, ",")
        push!(o_p_names_list, p_name)
    end
    return o_p_names_list
end

"""
    splitRenameParam(p_string::String, _splitter)
    splitRenameParam(_p::Symbol, _splitter)

Splits and renames a parameter based on a specified splitter.

# Arguments
- `p_string`: The input parameter to be split and renamed
    - `::String`: The parameter string to be split
    - `::Symbol`: The parameter symbol to be split
- `_splitter`: The delimiter used to split the parameter string

# Returns
A tuple containing the split and renamed parameter components.
"""
function splitRenameParam end

function splitRenameParam(_p::Symbol, _splitter)
    p_string = String(_p)
    return splitRenameParam(p_string, _splitter)
end

function splitRenameParam(p_string::String, _splitter)
    p_name = strip(p_string)
    if occursin(_splitter, p_string)
        p_split = split(p_string, _splitter)
        p_model = strip(first(p_split))
        p_param = strip(last(p_split))
        p_name = "$(p_model).$(p_param)"
    end
    return p_name
end


"""
    setInputParameters(original_table::Table, input_table::Table)

Updates input parameters by comparing an original table with an updated table from params.json.

# Arguments
- `original_table::Table`: The reference table containing original parameters
- `input_table::Table`: The table containing updated parameters to be compared with original

# Returns
a merged table with updated parameters
"""
function setInputParameters(original_table::Table, input_table::Table, model_timestep)
    print_info(setInputParameters, @__FILE__, @__LINE__, "→→→    override the default parameters and merge tables.")
    merged_table = copy(original_table)
    done_parameter_input = []
    skip_property = (:model_id, :initial, :default, :optimized, :approach_func, :lower, :upper)
    for i ∈ eachindex(input_table)
        subtbl = filter(
            row ->
                row.name == Symbol(input_table[i].name) &&row.model == Symbol(input_table[i].model) && row.name_full == input_table[i].name_full, original_table)
        if isempty(subtbl)
            error("parameter $(input_table[i].name) not found (model: $(input_table[i].model), name_full: $(input_table[i].name_full), approach: $(input_table[i].model_approach)). Make sure that the parameter exists in the selected approach/model structure or correct the parameter information in parameters input.")
        else
            pindx_p = findall(x -> x == input_table[i].name_full, merged_table.name_full)
            p_indx = pindx_p[1]
            if p_indx ∉ done_parameter_input
                push!(done_parameter_input, p_indx)
                t_actual = typeof(merged_table.initial[p_indx])
                input_timescale_run = ismissing(input_table.timescale_run[i]) ? "" : input_table.timescale_run[i]
                unit_factor = getUnitConversionForParameter(input_timescale_run, model_timestep)
                merged_table.initial[p_indx] = t_actual(input_table.optimized[i] * unit_factor)
                merged_table.optimized[p_indx] = t_actual(input_table.optimized[i] * unit_factor)
                merged_table.lower[p_indx] = t_actual(input_table.lower[i] * unit_factor)
                merged_table.upper[p_indx] = t_actual(input_table.upper[i] * unit_factor)
                for tp in propertynames(input_table)
                    if tp ∉ skip_property
                        in_pf = getproperty(input_table, tp)
                        me_pg = getproperty(merged_table, tp)
                        v_to_assign = in_pf[i]
                        if tp == :p_dist
                            v_to_assign = eval(Meta.parse(v_to_assign))
                        end
                        if ~ismissing(v_to_assign)
                            t_me_pg = typeof(me_pg[p_indx])
                            me_pg[p_indx] = t_me_pg(v_to_assign)
                        end
                    end
                end
            else
                error("Delete duplicate parameter at row $(i) for $(input_table[i].name) (name_full: $(input_table[i].name_full) in the parameter table (or line $(i+1) of input csv or model $(input_table[i].model_approach)). The same parameter was already used to update the model parameters.")
            end
        end
    end
    return merged_table
end
