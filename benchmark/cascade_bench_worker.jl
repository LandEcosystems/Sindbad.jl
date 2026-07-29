using Sindbad
using BenchmarkTools

if length(ARGS) < 3
    println(stderr, "usage: julia [+version] -t N --project=ENV cascade_bench_worker.jl <experiment_json> <replace_info_json|NONE> <output_csv>")
    exit(1)
end

experiment_json = ARGS[1]
replace_info_arg = ARGS[2]
output_csv = ARGS[3]

replace_info = if replace_info_arg == "NONE"
    Dict{String,Any}()
else
    Sindbad.JSON.parsefile(replace_info_arg)
end

info = getExperimentInfo(experiment_json; replace_info=replace_info)
forcing = getForcing(info)
info = drop_namedtuple_fields(info, (:settings,))

rows = Tuple{String,String,Any}[]  # (name, parent, thunk)
mode = :forward

try
    observations = getObservation(info, forcing.helpers)
    obs_array = [Array(_o) for _o in observations.data]

    opti_helpers = prepOpti(forcing, obs_array, info)
    cost_function = opti_helpers.cost_function
    default_values = opti_helpers.default_values
    parameter_scaling_type = info.optimization.run_options.parameter_scaling
    multi_constraint_method = info.optimization.run_options.multi_constraint_method
    cost_options = opti_helpers.cost_options
    parameter_table = info.optimization.parameter_table
    selected_models = info.models.forward
    run_helpers = opti_helpers.run_helpers

    runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
    output_array = run_helpers.output_array
    updated_models = updateModels(default_values, parameter_table, parameter_scaling_type, selected_models)
    land_copy = deepcopy(run_helpers.space_land)
    cost_vector = metricVector(output_array, obs_array, cost_options)

    rep_option = first(cost_options)
    ŷ_rep = output_array[rep_option.mod_ind]
    if size(ŷ_rep, 2) == 1
        ŷ_rep = getModelOutputView(ŷ_rep)
    end
    y_rep = obs_array[rep_option.obs_ind]
    yσ_rep = obs_array[rep_option.obs_ind+1]
    y_h, yσ_h, ŷ_h = Sindbad.DataLoaders.getHarmonizedData(y_rep, yσ_rep, ŷ_rep, rep_option)
    rep_name = string(rep_option.variable)

    push!(rows, ("cost_function(x)", "(optimizer)", () -> cost_function(default_values)))
    push!(rows, ("cost(...)", "cost_function(x)", () -> cost(default_values, default_values, selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, output_array, run_helpers.space_output, land_copy, run_helpers.tem_info, obs_array, parameter_table, cost_options, multi_constraint_method, parameter_scaling_type, Sindbad.CostModelObs())))
    push!(rows, ("updateModels", "cost(...)", () -> updateModels(default_values, parameter_table, parameter_scaling_type, selected_models)))
    push!(rows, ("runTEM!", "cost(...)", () -> runTEM!(updated_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, land_copy, run_helpers.tem_info)))
    push!(rows, ("metricVector", "cost(...)", () -> metricVector(output_array, obs_array, cost_options)))
    push!(rows, ("combineMetric", "cost(...)", () -> combineMetric(cost_vector, multi_constraint_method)))
    push!(rows, ("getData(:$rep_name)", "metricVector", () -> getData(output_array, obs_array, rep_option)))
    push!(rows, ("getHarmonizedData(:$rep_name)", "getData(:$rep_name)", () -> Sindbad.DataLoaders.getHarmonizedData(y_rep, yσ_rep, ŷ_rep, rep_option)))
    push!(rows, ("getDataWithoutNaN(:$rep_name)", "metricVector", () -> getDataWithoutNaN(y_h, yσ_h, ŷ_h, rep_option.valids)))
    push!(rows, ("metric(:$rep_name)", "metricVector", () -> metric(rep_option.cost_metric, ŷ_h, y_h, yσ_h)))
    global mode = :optimization
catch e
    @warn "optimization cascade unavailable for this experiment; falling back to forward-only benchmark" exception=e
    run_helpers = prepTEM(forcing, info)
    push!(rows, ("prepTEM", "(root)", () -> prepTEM(forcing, info)))
    push!(rows, ("runTEM!", "(root)", () -> runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)))
    global mode = :forward
end

open(output_csv, "w") do io
    println(io, "# JULIAVER=", VERSION, " NTHREADS=", Threads.nthreads(), " MODE=", mode)
    println(io, "name,parent,time_ns,allocs,memory_bytes")
    for (name, parent, thunk) in rows
        thunk() # warmup / compile
        b = @benchmark $thunk() samples=30 seconds=3
        t = minimum(b.times)
        println(io, name, ",", parent, ",", t, ",", b.allocs, ",", b.memory)
    end
end

println("wrote ", output_csv)
