export prepTEMYax

"""
    getTemplateLandYax(selected_models, forcing, info, tem_info, land_init, forcing_data_info)

Builds the land that every location of a lazy run starts from, with every field of the
selected models in its final type, as `runTEMOne` does for an eager run.

# Notes:
- The land is built from a placeholder forcing, see `getPlaceholderForcingYax`, so no
  forcing is read and no location has to be valid.
- The model errors are not caught in this step, since the placeholder values of
  different variables are not consistent with each other. The values of the land are
  set again for every location by define and precompute.
"""
function getTemplateLandYax(selected_models, forcing, info, tem_info, land_init, forcing_data_info)
    loc_forcing = getPlaceholderForcingYax(forcing, info, forcing_data_info, getTestForcing())
    loc_forcing_t = getForcingForTimeStep(loc_forcing, loc_forcing, 1, tem_info.vals.forcing_types)
    model_helpers = (; tem_info.model_helpers..., run=(; tem_info.model_helpers.run..., catch_model_errors=DoNotCatchModelErrors()))
    return buildFullLand(selected_models, loc_forcing_t, deepcopy(land_init), model_helpers)
end

"""
    getPlaceholderForcingYax(forcing, info, forcing_data_info, test_forcing)

Returns a forcing NT of one location with the same types as the forcing that `TEMYax`
builds from the cubes.

# Arguments:
- `test_forcing`: the forcing of one location from `getTestForcing`, whose values are
  used for the variables it has

# Notes:
- An array has the core dimensions of its cube, i.e., all dimensions but the spatial
  ones. The time dimension has a length of 1, and the other dimensions, e.g., soil
  layers, keep their length.
- A test value with another number of layers than the cube is replaced by its mean.
- A variable that is not in `test_forcing` is filled with the middle of its bounds, or
  with one when it has no bounds. The middle of the bounds is not valid for every
  variable, e.g., soil texture, whose bounds are in percent while the values are
  fractions, so the test values are preferred.
"""
function getPlaceholderForcingYax(forcing, info, forcing_data_info, test_forcing)
    num_type = info.helpers.numbers.num_type
    time_name = Symbol(info.experiment.data_settings.forcing.data_dimension.time)
    arrays = map(Tuple(forcing.variables), Tuple(values(forcing.data)), Tuple(forcing.dims), forcing_data_info) do var_name, cube, core_dims, data_info
        sizes = map(d -> d == time_name ? 1 : length(DD.dims(cube, d)), core_dims)
        test_value = get(test_forcing, Symbol(var_name), nothing)
        if isnothing(test_value)
            bounds = data_info.bounds
            value = isnothing(bounds) || isempty(bounds) ? one(num_type) : num_type((first(bounds) + last(bounds)) / 2)
            fill(value, sizes...)
        elseif test_value isa Number
            fill(num_type(test_value), sizes...)
        elseif length(test_value) == prod(sizes)
            reshape(num_type.(vec(test_value)), sizes...)
        else
            fill(num_type(sum(test_value) / length(test_value)), sizes...)
        end
    end
    return (; Pair.(forcing.variables, arrays)...)
end

"""
    getTestForcing()

Returns the forcing of one location in the test data of SindbadTEM, `tmp_forcing` in
`test/test_data/forcing.jl`, or an empty NT when the file is not found.

# Notes:
- Only the `tmp_forcing` expression of the file is evaluated, in a new module, so the
  packages that the file loads do not have to be available.
"""
function getTestForcing()
    path = joinpath(pkgdir(SindbadTEM), "test", "test_data", "forcing.jl")
    isfile(path) || return (;)
    for ex ∈ Meta.parseall(read(path, String)).args
        if ex isa Expr && ex.head == :(=) && ex.args[1] == :tmp_forcing
            return Core.eval(Module(), ex.args[2])
        end
    end
    return (;)
end

"""
    getForcingDataInfo(info, forcing_vars)

Returns the cleaning info of every forcing variable, i.e., the settings of the variable
merged into `default_forcing` the same way as in `getForcing`.

# Arguments:
- `info`: a SINDBAD NT with all information needed for setup and execution of an experiment
- `forcing_vars`: the names of the forcing variables, in the order of the forcing cubes

# Notes:
- An empty or null setting of a variable, such as `"bounds": []`, keeps the value of
  `default_forcing`, whose bounds are always typed. The merge is done once here rather
  than for every pixel.
- Only the fields that `cleanData` reads are kept. The info is part of the argument
  types of `TEMYax`, and the full settings, e.g., with the `dimension` and
  `interpolation_method` groups, make it slow to compile.
"""
function getForcingDataInfo(info, forcing_vars)
    default_info = info.experiment.data_settings.forcing.default_forcing
    vars_info = info.experiment.data_settings.forcing.variables
    return map(Tuple(forcing_vars)) do v
        v_info = merge_namedtuple_prefer_nonempty(default_info, getproperty(vars_info, Symbol(v)))
        (; source_to_sindbad_unit=v_info.source_to_sindbad_unit, additive_unit_conversion=v_info.additive_unit_conversion, bounds=v_info.bounds)
    end
end

"""
    shareForcingCubesYax(info, forcing)

Returns the forcing cubes of a lazy run with one cube per source, their core
dimensions, and the index of the cube of each forcing variable.

# Notes:
- Each forcing variable is its own cube, and the run reads and decompresses every
  input cube of a block. Variables that read the same source variable of the same
  file, with the same dimensions and interpolation, e.g., `f_airT` and `f_airT_day`,
  or a placeholder that multiplies a source by zero, then read it more than once.
  Such variables share the cube of the first of them.
- The units and bounds are applied per variable in `TEMYax`, so variables that share a
  cube can differ in them.
- `exe_rules.yax_shared_forcing` set to `false` keeps one cube per variable.
"""
function shareForcingCubesYax(info, forcing)
    cubes = Tuple(values(forcing.data))
    dims = Tuple(forcing.dims)
    all_sources = Tuple(eachindex(cubes))
    get(info.experiment.exe_rules, :yax_shared_forcing, true) || return cubes, dims, all_sources
    forcing_settings = info.experiment.data_settings.forcing
    source_keys = map(Tuple(forcing.variables), cubes) do var_name, cube
        v_info = getForcingVariableInfo(forcing_settings.default_forcing, getproperty(forcing_settings.variables, Symbol(var_name)), forcing_settings)
        (something(v_info.data_path, ""), v_info.source_variable, v_info.space_time_type, v_info.dimension, v_info.interpolation_method, DD.dims(cube))
    end
    first_of_source = map(k -> findfirst(==(k), source_keys), source_keys)
    unique_firsts = unique(first_of_source)
    length(unique_firsts) == length(cubes) && return cubes, dims, all_sources
    sources = map(i -> findfirst(==(i), unique_firsts), first_of_source)
    print_info(shareForcingCubesYax, @__FILE__, @__LINE__, "$(length(cubes)) forcing variables read $(length(unique_firsts)) sources, each source is read once", n_m=4)
    return Tuple(cubes[i] for i ∈ unique_firsts), Tuple(dims[i] for i ∈ unique_firsts), sources
end

"""
    prepTEMYax(selected_models, forcing::NamedTuple, info::NamedTuple)

Builds the lazy run of the TEM over the forcing cubes with `xmap`, without running
it. `runTEMYax` runs it.

# Arguments:
- `selected_models`: a tuple of all models selected in the given model structure
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `info`: a SINDBAD NT with all information needed for setup and execution of an experiment

# Returns:
- a NamedTuple with the `output` Dataset, the `restart` Dataset with the pools after
  spinup, the `restart_vars` written to it, and the `spinup_mode` of the step that saved
  the restart
"""
function prepTEMYax(selected_models, forcing::NamedTuple, info::NamedTuple)
    # forcing/input information, one cube per source so that no source is read twice
    forcing_cubes, forcing_dims, forcing_sources = shareForcingCubesYax(info, forcing)
    incubes = map(hideCubeType, forcing_cubes);
    indims = forcing_dims;
    n_forcing_cubes = length(incubes)
    # a spatial parameter has no core dimensions, so each location gets one value, and a
    # spatiotemporal one has time, so each location gets its values over time like a
    # forcing. The values set the parameters of the models of the location in TEMYax.
    parameter_cubes, parameter_dims, parameter_to_index, parameter_time = getParameterCubesYax(selected_models, forcing)
    incubes = (incubes..., parameter_cubes...)
    indims = (indims..., parameter_dims...)
    # information for running model
    run_helpers = prepTEM(forcing, info);
    _num_type = Val{info.helpers.numbers.num_type}()
    _forcing_data_info = getForcingDataInfo(info, forcing.variables)
    # every location starts from this land, so the land keeps one type in all models
    loc_land = getTemplateLandYax(selected_models, forcing, info, run_helpers.tem_info, run_helpers.loc_land, _forcing_data_info)
    checkOutputLayers(info.output.variables, info.output.depth_info, loc_land)
    #output = XOutput.(getproperty.(run_helpers.output_dims, :axisdesc))
    output = run_helpers.output_dims
    # the template land has every pool
    restart = getRestartDimsArrays(info, forcing.helpers, loc_land)
    restart_vars = restart.variables
    restart_output = getRestartOutDimsYax(info, restart.dims_pairs)
    all_output = (output..., restart_output...)
    # DiskArrayEngine needs all output cubes to have the same dimensions, so every cube
    # is padded with singleton versions of the dimensions of the other cubes.
    alloutdims = union(getproperty.(all_output, :outaxes)...)
    new_output = map(all_output) do out
        singleton_dims = setdiff(alloutdims, out.outaxes)
        newdims = (out.outaxes..., DD.rebuild.(singleton_dims, (1:1,))...) 
        YAXArrays.XOutput(newdims, out.destroyaxes, out.outtype, out.properties)
    end
    tem_kwargs = (selected_models=selected_models,
        forcing_vars=forcing.variables,
        forcing_sources=forcing_sources,
        output_vars=run_helpers.output_vars,
        loc_land=loc_land,
        tem=run_helpers.tem_info,
        clean_data=(; _num_type, _forcing_data_info),
        restart_vars=restart_vars,
        parameter_to_index=parameter_to_index,
        parameter_time=parameter_time)
    outcubes = xmap(TEMYaxFromRef,
        (incubes .⊘ indims)...;
    # the arguments become part of the type of every function of the xmap run, so they
    # are passed behind a Ref{Any} to keep those types small and fast to compile
    function_kwargs = (tem_kwargs=Ref{Any}(tem_kwargs),),
        output = new_output,
        # xmap runs the pixels of a block on one thread unless this is set. The number of
        # threads of the Julia session decides how many are used.
        allow_threads = true,
        #outdims=run_helpers.output_dims,
        #max_cache=info.experiment.exe_rules.yax_max_cache,
        #ispar=false,
        )
    # the cubes are kept in a Vector{Any}, as code for the tuple of all their types is
    # slow to compile
    outcubes = outcubes isa YAXArray ? Any[outcubes] : collect(Any, outcubes)
    n_out = length(output)
    varnames = Tuple(getUniqueVarNames(info.output.variables))
    restart_names = Tuple(last.(restart_vars))
    # besides the padding, xmap adds a singleton for every core dimension of the forcing
    # that the output does not have, e.g. the soil layers of the texture forcing
    space_dims = Symbol.(info.experiment.data_settings.forcing.data_dimension.space)
    padded_names = Vector{Symbol}[setdiff(DD.name.(DD.dims(o_cube)), (DD.name.(out.outaxes)..., space_dims...)) for (out, o_cube) ∈ zip(collect(Any, all_output), outcubes)]
    dropped_cubes = Any[dropPaddedDimsYax(o_cube, padded) for (o_cube, padded) ∈ zip(outcubes, padded_names)]
    output_ds = datasetFromCubes(varnames, dropped_cubes[1:n_out])
    restart_ds = datasetFromCubes(restart_names, dropped_cubes[(n_out+1):end])
    # a pool can also be an output variable, so the restart cubes get their own keys
    restart_keys = map(r -> Symbol("restart_", r), restart_names)
    xmap_keys = (varnames..., restart_keys...)
    xmap_cubes = (; dataset=datasetFromCubes(xmap_keys, outcubes),
        padded_names=Dict(zip(xmap_keys, padded_names)),
        output_names=varnames, restart_names=restart_names, restart_keys=restart_keys,
        in_cubes=incubes, n_forcing=n_forcing_cubes)
    return (; output=output_ds, restart=restart_ds, restart_vars=restart_vars, spinup_mode=getSaveRestartSpinupMode(info), xmap=xmap_cubes)
end

"""
    getRestartOutDimsYax(info, restart_dims_pairs)

Builds one `XOutput` per restart variable from its dimension pairs, leaving out the
spatial dimensions that `xmap` loops over.

# Arguments:
- `info`: a SINDBAD NT with all information needed for setup and execution of an experiment
- `restart_dims_pairs`: the dimension pairs of each restart variable without time
"""
function getRestartOutDimsYax(info, restart_dims_pairs)
    space_dims = Symbol.(info.experiment.data_settings.forcing.data_dimension.space)
    return map(Tuple(restart_dims_pairs)) do dim_pairs
        vdims = []
        for _dim in dim_pairs
            if first(_dim) ∉ space_dims
                push!(vdims, DD.rebuild(DD.Dimensions.name2dim(first(_dim)), last(_dim)))
            end
        end
        YAXArrays.XOutput(vdims...)
    end
end

"""
    getParameterCubesYax(selected_models, forcing)

Returns the cubes of the parameters per location, their core dimensions, and the index
of each parameter in the models, for the input cubes of `xmap`.

# Returns:
- `()`, `()`, `nothing` and `nothing` when `forcing.parameters` is `nothing`, so the
  input cubes of `xmap` are only the forcing.
- Otherwise:
  - the cubes of `forcing.parameters.data`, which hold values that are already in run
    units and within bounds, with their types hidden like the forcing cubes
  - the core dimensions of each cube, `(time,)` for a parameter with time, else `()`
  - the `parameter_to_index` from `getParameterIndices`
  - the `getTimeVaryingInfo` of the parameters, `nothing` when none varies in time
"""
function getParameterCubesYax(selected_models, forcing)
    forcing_parameters = get(forcing, :parameters, nothing)
    isnothing(forcing_parameters) && return (), (), nothing, nothing
    parameter_to_index = getParameterIndices(selected_models, forcing_parameters.parameter_table)
    parameter_time = getTimeVaryingInfo(selected_models, parameter_to_index, forcing_parameters)
    parameter_cubes = map(hideCubeType, Tuple(forcing_parameters.data))
    return parameter_cubes, Tuple(forcing_parameters.dims), parameter_to_index, parameter_time
end
