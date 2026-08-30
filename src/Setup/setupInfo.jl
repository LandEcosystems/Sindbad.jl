export setupInfo
export createInitLand
export getSpinupSequenceWithTypes

"""
    createInitLand(pool_info, tem)

Initializes the land state by creating a NamedTuple with pools, states, and selected models.

# Arguments:
- `pool_info`: Information about the pools to initialize.
- `tem`: A helper NamedTuple with necessary objects for pools and numbers.

# Returns:
- A NamedTuple containing initialized pools, states, fluxes, diagnostics, properties, models, and constants.

# Examples
```jldoctest
julia> using Sindbad

julia> # Initialize land state for an experiment
julia> # init_land = createInitLand(pool_info, tem)
```
"""
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

"""
    parseSaveCode(info)

Parses and saves the code and structs of the selected model structure for the given experiment.

# Arguments:
- `info`: The experiment configuration NamedTuple containing model and output information.

# Notes:
- Writes the `define`, `precompute`, and `compute` functions for the selected models to separate files.
- Also writes the parameter structs for the models.
"""
function parseSaveCode(info)
    print_info(parseSaveCode, @__FILE__, @__LINE__, "saving Selected Models Code...")
    models = info.temp.models.forward
    outfile_define = joinpath(info.output.dirs.code, info.temp.experiment.basics.name * "_" * info.temp.experiment.basics.domain * "_model_definitions.jl")
    outfile_code = joinpath(info.output.dirs.code, info.temp.experiment.basics.name * "_" * info.temp.experiment.basics.domain * "_model_functions.jl")
    outfile_struct = joinpath(info.output.dirs.code, info.temp.experiment.basics.name * "_" * info.temp.experiment.basics.domain * "_model_structs.jl")
    fallback_code_define = nothing
    fallback_code_precompute = nothing
    fallback_code_compute = nothing

    # Write define functions
    open(outfile_define, "w") do o_file
        mod_string = "# Code for define functions (variable definition) in models of SINDBAD for $(info.settings.experiment.basics.name) experiment applied to $(info.settings.experiment.basics.domain) domain.\n"
        mod_string *= "# These functions are called just ONCE for variable/array definitions.\n"
        write(o_file, mod_string)
        mod_string = "# Based on @code_string from CodeTracking.jl. In case of conflicts, follow the original code in define functions of model approaches in src/Models/[model]/[approach].jl\n"
        write(o_file, mod_string)
        for (mi, _mod) in enumerate(models)
            mod_name = string(nameof(supertype(typeof(_mod))))
            appr_name = string(nameof(typeof(_mod)))
            mod_string = "\n# $appr_name\n"
            write(o_file, mod_string)
            # @show(_mod, mod_name, appr_name, string(first(methods(typeof(_mod))).file))
            mod_file = string(first(methods(typeof(_mod))).file)
            # mod_file = joinpath(info.temp.experiment.dirs.sindbad, "src/Processes", mod_name, appr_name * ".jl")
            write(o_file, "# " * mod_file * "\n")
            mod_string = "# Call order: $mi\n\n"
            write(o_file, mod_string)

            mod_ending = "\n\n"
            if mi == lastindex(models)
                mod_ending = "\n"
            end
            mod_code = @code_string SindbadTEM.Processes.define(_mod, nothing, nothing, nothing)
            if occursin("LandEcosystem", mod_code)
                if isnothing(fallback_code_define)
                    fallback_code_define = mod_code
                end
            else
                write(o_file, mod_code * mod_ending)
            end
            mod_string = "# --------------------------------------\n"
            write(o_file, mod_string)
        end
        mod_string = "\n# Fallback define function for LandEcosystem\n"
        write(o_file, mod_string)
        if !isnothing(fallback_code_define)
            write(o_file, fallback_code_define)
        end
    end

    # Write precompute and compute functions
    open(outfile_code, "w") do o_file
        mod_string = "# Code for precompute and compute functions in models of SINDBAD for $(info.settings.experiment.basics.name) experiment applied to $(info.settings.experiment.basics.domain) domain.\n"
        mod_string *= "# Precompute functions are called once outside the time loop per iteration in optimization, while compute functions are called every time step.\n"
        write(o_file, mod_string)
        mod_string = "# Based on @code_string from CodeTracking.jl. In case of conflicts, follow the original code in model approaches in src/Processes/[model]/[approach].jl\n"
        write(o_file, mod_string)
        for (mi, _mod) in enumerate(models)
            mod_name = string(nameof(supertype(typeof(_mod))))
            appr_name = string(nameof(typeof(_mod)))
            mod_string = "\n# $appr_name\n"
            write(o_file, mod_string)
            mod_file = string(first(methods(typeof(_mod))).file)
            # mod_file = joinpath(info.temp.experiment.dirs.sindbad, "src/Processes", mod_name, appr_name * ".jl")
            write(o_file, "# " * mod_file * "\n")
            mod_string = "# Call order: $mi\n\n"
            write(o_file, mod_string)

            mod_ending = "\n\n"

            mod_code = @code_string SindbadTEM.Processes.precompute(_mod, nothing, nothing, nothing)

            if occursin("LandEcosystem", mod_code)
                if isnothing(fallback_code_precompute)
                    fallback_code_precompute = mod_code * "\n\n"
                end
            else
                write(o_file, mod_code * mod_ending)
            end

            mod_code = @code_string SindbadTEM.Processes.compute(_mod, nothing, nothing, nothing)
            if occursin("LandEcosystem", mod_code)
                if isnothing(fallback_code_compute)
                    fallback_code_compute = mod_code
                end
            else
                write(o_file, mod_code * mod_ending)
            end
            mod_string = "# --------------------------------------\n"
            write(o_file, mod_string)
        end
        mod_string = "\n# Fallback precompute and compute functions for LandEcosystem\n"
        write(o_file, mod_string)
        if !isnothing(fallback_code_precompute)
            write(o_file, fallback_code_precompute)
        end
        if !isnothing(fallback_code_compute)
            write(o_file, fallback_code_compute)
        end
    end

    # Write structs
    open(outfile_struct, "w") do o_file
        mod_string = "# Code for parameter structs of SINDBAD for $(info.settings.experiment.basics.name) experiment applied to $(info.settings.experiment.basics.domain) domain.\n"
        mod_string *= "# Based on @code_expr from CodeTracking.jl. In case of conflicts, follow the original code in model approaches in src/Processes/[model]/[approach].jl\n\n"
        write(o_file, mod_string)
        write(o_file, "abstract type LandEcosystem end\n")

        for (mi, _mod) in enumerate(models)
            mod_name = string(nameof(supertype(typeof(_mod))))
            appr_name = string(nameof(typeof(_mod)))
            mod_file = string(first(methods(typeof(_mod))).file)
            # mod_file = joinpath(info.temp.experiment.dirs.sindbad, "src/Processes", mod_name, appr_name * ".jl")
            mod_string = "\n# $appr_name\n"
            write(o_file, mod_string)
            write(o_file, "# " * mod_file * "\n")
            mod_string = "# Call order: $mi\n\n"
            write(o_file, mod_string)

            write(o_file, "abstract type $mod_name <: LandEcosystem end\n\n")

            mod_string = string(@code_expr typeof(_mod)())
            for xx = 1:100
                if occursin(mod_file, mod_string)
                    mod_string = replace(mod_string, "#= $(mod_file):$(xx) =#\n" => "")
                    mod_string = replace(mod_string, "#= $(mod_file):$(xx) =#" => "")
                end
            end
            mod_string = replace(mod_string, " @bounds " => "@bounds")
            mod_string = replace(mod_string, "@describe(" => "@describe")
            mod_string = replace(mod_string, "@units(" => "@units")
            mod_string = replace(mod_string, "@timescale(" => "@timescale")
            mod_string = replace(mod_string, "@with_kw(" => "@with_kw ")
            mod_string = replace(mod_string, "                    end))))" => "end")
            mod_string = replace(mod_string, "                end))))" => "end")
            mod_string = replace(mod_string, "\n    end" => " end")
            mod_string = replace(mod_string, "                                                " => "    ")
            mod_string = replace(mod_string, " = (((" => " = ")
            mod_string = replace(mod_string, ") |" => " |")
            mod_string = replace(mod_string, "] |" => "]) |")
            write(o_file, mod_string * "\n\n")
            mod_string = "# --------------------------------------\n"
            if mi == lastindex(models)
                mod_string = "# --------------------------------------"
            end
            write(o_file, mod_string)
        end
    end

    return nothing
end


"""
    setDatesInfo(info::NamedTuple)

Fills `info.temp.helpers.dates` with date and time-related fields needed in the models.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with date-related fields added.
"""
function setDatesInfo(info::NamedTuple)
    print_info(setDatesInfo, @__FILE__, @__LINE__, "setting Dates Helpers...")
    tmp_dates = (;)
    time_info = getfield(info.settings.experiment.basics, :time)
    time_props = propertynames(time_info)
    for time_prop ∈ time_props
        prop_val = getfield(time_info, time_prop)
        if prop_val isa Number
            prop_val = info.temp.helpers.numbers.num_type(prop_val)
        end
        tmp_dates = set_namedtuple_field(tmp_dates, (time_prop, prop_val))
    end
    tr_n, tr_unit = parseTemporalResolution(info.settings.experiment.basics.time.temporal_resolution)
    timestep = getfield(Dates, Symbol(titlecase(tr_unit)))(tr_n)
    time_range = DateTime(info.settings.experiment.basics.time.date_begin):timestep:DateTime(info.settings.experiment.basics.time.date_end)
    tmp_dates = set_namedtuple_field(tmp_dates, (:temporal_resolution, info.settings.experiment.basics.time.temporal_resolution))
    tmp_dates = set_namedtuple_field(tmp_dates, (:timestep, timestep))
    tmp_dates = set_namedtuple_field(tmp_dates, (:range, time_range))
    tmp_dates = set_namedtuple_field(tmp_dates, (:size, length(time_range)))
    info = (; info..., temp=(; info.temp..., helpers=(; info.temp.helpers..., dates=tmp_dates)))
    return info
end


"""
    setModelRunInfo(info::NamedTuple)

Sets up model run flags and output array types for the experiment.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with model run flags and output array types added.
"""
function setModelRunInfo(info::NamedTuple)
    print_info(setModelRunInfo, @__FILE__, @__LINE__, "setting Model Run Flags...")
    if info.settings.experiment.flags.run_optimization
        info = @set info.settings.experiment.flags.catch_model_errors = false
    end
    run_vals = convertRunFlagsToTypes(info)
    # check if lazy run is set, and if so, set output array type to YAXArray regardless of the setting in json, as well as land output type to YAXArray
    run_lazy = get(info.settings.experiment.flags, :run_lazy, false)

    in_output_array_type = info.settings.experiment.model_output.output_array_type
    if run_lazy
        in_output_array_type = "YAXArray"
    end
    output_array_type = getfield(Types, to_uppercase_first(in_output_array_type, "Output"))()
    run_info = (; run_vals..., output_array_type = output_array_type)

    run_info = set_namedtuple_field(run_info, (:run_lazy, getTypeInstanceForFlags(:run_lazy, run_lazy, "Do")))

    run_info = set_namedtuple_field(run_info, (:save_single_file, getTypeInstanceForFlags(:save_single_file, info.settings.experiment.model_output.save_single_file, "Do")))
    # a lazy run always needs lazy (YAXArray) forcing/observation data; a non-lazy run always needs KeyedArray
    input_array_type = run_lazy ? InputYAXArray() : InputKeyedArray()
    run_info = set_namedtuple_field(run_info, (:input_array_type, input_array_type))

    parallelization = titlecase(info.settings.experiment.exe_rules.parallelization)
    run_info = set_namedtuple_field(run_info, (:parallelization, getfield(Types, Symbol(parallelization*"Parallelization"))()))

    # if lazy, the run helpers will handle the output array type and land output type, so we set those to YAXArray here regardless of the setting in json, and the run helpers will overwrite it if not lazy
    in_land_output_type = info.settings.experiment.exe_rules.land_output_type
    if run_lazy
        in_land_output_type = "YAXArray"
    end
    land_output_type = getfield(Types, to_uppercase_first(in_land_output_type, "PreAlloc"))()
    run_info = set_namedtuple_field(run_info, (:land_output_type, land_output_type))

    ## visualization backend
    visualization_backend = get(info.settings.experiment.exe_rules, :visualization_backend, "Types")
    visualization_backend_type = getfield(Types, to_uppercase_first(visualization_backend, "Visualization"))()
    run_info = set_namedtuple_field(run_info, (:visualization_backend, visualization_backend_type))
    
    info = (; info..., temp=(; info.temp..., helpers=(; info.temp.helpers..., run=run_info)))
    return info
end

"""
    setNumericHelpers(info::NamedTuple, ttype)

Prepares numeric helpers for maintaining consistent data types across models.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.
- `ttype`: The numeric type to use (default: `info.settings.experiment.exe_rules.model_number_type`).

# Returns:
- The updated `info` NamedTuple with numeric helpers added.
"""
function setNumericHelpers(info::NamedTuple, ttype=info.settings.experiment.exe_rules.model_number_type)
    print_info(setNumericHelpers, @__FILE__, @__LINE__, "setting Numeric Helpers...")
    num_type = getNumberType(ttype)
    tolerance = num_type(info.settings.experiment.exe_rules.tolerance)
    num_helpers = (; tolerance=tolerance, num_type=num_type)
    info = (; info..., temp=(; info.temp..., helpers=(; numbers=num_helpers)))
    return info
end


"""
    setRestartFilePath(info::NamedTuple)

Validates and sets the absolute path for the restart file used in spinup.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with the absolute restart file path set.
"""
function setRestartFilePath(info::NamedTuple)
    restart_file_in = get(info.settings.experiment.model_spinup, :restart_file, nothing)
    restart_file = nothing

    if !isnothing(restart_file_in)
        if restart_file_in[(end-4):end] != ".jld2"
            error(
                "info.settings.experiment.model_spinup.restartFile has a file ending other than .jld2. Only jld2 files are supported for loading spinup. Either give a correct file or set info.settings.experiment.flags.load_spinup to false."
            )
        end
        if isabspath(restart_file_in)
            restart_file = restart_file_in
        else
            restart_file = joinpath(info.temp.experiment.dirs.experiment, restart_file_in)
        end
        info = @set info.settings.experiment.model_spinup.restart_file = restart_file
    end
    return info
end

"""
    getSpinupSequenceWithTypes(seqq, helpers_dates)

Processes the spinup sequence and assigns types for temporal aggregators for spinup forcing.

# Arguments:
- `seqq`: The spinup sequence from the experiment configuration.
- `helpers_dates`: A NamedTuple containing date-related helpers.

# Returns:
- A processed spinup sequence with forcing types for temporal aggregators.
"""
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
        sst = SpinupSequenceWithAggregator(seq["forcing"], seq["n_repeat"], seq["n_timesteps"], seq["spinup_mode"], optns, seq["aggregator_indices"], Vector{TimeSample}(seq["aggregator"]), seq["aggregator_type"]);
        push!(seqq_typed, sst)
    end
    return seqq_typed
end

"""
    setSpinupInfo(info::NamedTuple)

Processes the spinup configuration and prepares the spinup sequence.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with spinup-related fields added.
"""
function setSpinupInfo(info)
    print_info(setSpinupInfo, @__FILE__, @__LINE__, "setting Spinup Info...")
    info = setRestartFilePath(info)
    infospin = info.settings.experiment.model_spinup
    # change spinup sequence dispatch variables to Val, get the temporal aggregators
    seqq = get(infospin, :sequence, nothing)
    if !isnothing(seqq)
        seqq_typed = getSpinupSequenceWithTypes(seqq, info.temp.helpers.dates)
        infospin = set_namedtuple_field(infospin, (:sequence, Tuple(seqq_typed)))
    end
    info = set_namedtuple_subfield(info, :temp, (:spinup, infospin))
    return info
end


"""
    setExperimentBasics(info::NamedTuple)

Copies basic experiment information into the temporary experiment configuration.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with basic experiment information added.
"""
function setExperimentBasics(info)
    print_info(setExperimentBasics, @__FILE__, @__LINE__, "setting Basic Experiment Info...")
    ex_basics = info.settings.experiment.basics
    ex_basics_sel = (;)
    for k in propertynames(ex_basics)
        if k !== :config_files
            if k == :time
                ex_basics_sel = set_namedtuple_field(ex_basics_sel, (:temporal_resolution, getfield(ex_basics[:time], :temporal_resolution)))
            else
                ex_basics_sel = set_namedtuple_field(ex_basics_sel, (k, getfield(ex_basics, k)))
            end 
        end
    end
    exp_name_domain = ex_basics.domain * "_" * ex_basics.name
    ex_basics_sel = (; ex_basics_sel..., id=exp_name_domain)
    info = (; info..., temp=(; info.temp..., experiment=(; info.temp.experiment..., basics=ex_basics_sel)))
    return info
end

"""
    setupInfo(info::NamedTuple)

Processes the experiment configuration and sets up all necessary fields for model simulation.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with all necessary fields for model simulation.
"""
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

    data_settings = (;)
    if hasproperty(info.settings, :forcing)
        data_settings = set_namedtuple_field(data_settings, (:forcing, info.settings.forcing))
    end
    if (info.settings.experiment.flags.run_optimization || info.settings.experiment.flags.calc_cost) && hasproperty(info.settings.optimization, :algorithm_optimization)
        # @info "  setupInfo: setting ParameterOptimization and Observation info..."
        info = setOptimization(info)
        data_settings = set_namedtuple_field(data_settings, (:optimization, info.settings.optimization))
    else
        parameter_table = get(info.temp.models, :parameter_table, nothing)
        if !isnothing(parameter_table)
            checkParameterBounds(parameter_table.name, parameter_table.initial, parameter_table.lower, parameter_table.upper, ScaleNone(), p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)
        end
     end

    if hasproperty(info.settings, :hybrid)
        info = setHybridInfo(info)
    end

    if !isnothing(info.settings.experiment.exe_rules.longtuple_size)
        selected_approach_forward = to_longtuple(info.temp.models.forward, info.settings.experiment.exe_rules.longtuple_size)
        info = @set info.temp.models.forward = selected_approach_forward
    end

    print_info(setupInfo, @__FILE__, @__LINE__, "Cleaning Info Fields...")
    exe_rules = info.settings.experiment.exe_rules
    info = drop_namedtuple_fields(info, (:model_structure, :experiment, :output, :pools))
    info = (; info..., info.temp...)
    info = set_namedtuple_subfield(info, :experiment, (:data_settings, data_settings))
    info = set_namedtuple_subfield(info, :experiment, (:exe_rules, exe_rules))
    info = drop_namedtuple_fields(info, (:temp, :settings,))
    return info
end

