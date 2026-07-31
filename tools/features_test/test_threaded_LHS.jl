using Revise
using SindbadTEM
using Sindbad

using QuasiMonteCarlo
toggle_type_abbrev_in_stacktrace()
experiment_json = "../../examples/setups/WROASTED/experiment.json"

site_index = 1
optimize_it = true
path_output = nothing

set_log_level(:info)
parameter_set_size = 2000

parallelization_lib = "threads"
model_array_type = "static_array"
replace_info = Dict("experiment.basics.name" => "WROASTED_threaded_LHS",
    "forcing.subset.site" => [site_index],
    "experiment.flags.run_optimization" => optimize_it,
    "experiment.flags.calc_cost" => true,
    "experiment.flags.catch_model_errors" => false,
    "experiment.flags.spinup_TEM" => true,
    "experiment.flags.debug_model" => false,
    "experiment.exe_rules.land_output_type" => "array_MT",
    "experiment.exe_rules.model_array_type" => model_array_type,
    "experiment.model_output.path" => path_output,
    "experiment.model_output.format" => "nc",
    "experiment.model_output.save_single_file" => true,
    "experiment.exe_rules.parallelization" => parallelization_lib,
    "optimization.algorithm_optimization" => "CMAEvolutionStrategy_CMAES.json",
    "optimization.subset_model_output" => false,
    "optimization.optimization_cost_threaded" => parameter_set_size)

info = getExperimentInfo(experiment_json; replace_info=replace_info); # note that this will modify information from json with the replace_info

forcing = getForcing(info);

run_helpers = prepTEM(forcing, info);
# @time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info);

observations = getObservation(info, forcing.helpers);
obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because 

parameter_table = info.optimization.parameter_table;
defaults = parameter_table.initial;

parameter_samples = QuasiMonteCarlo.sample(parameter_set_size, parameter_table.lower, parameter_table.upper, LatinHypercubeSample());
cost_samples_c = Array{Float32}(undef, parameter_set_size) # cost_func
cost_samples_b = Array{Float32}(undef, parameter_set_size) # brute/serial
cost_samples_s = Array{Float32}(undef, parameter_set_size) # spawn
cost_samples_t = Array{Float32}(undef, parameter_set_size) # threaded


cost_options = prepCostOptions(obs_array, info.optimization.cost_options);
parameter_scaling_type = info.optimization.run_options.parameter_scaling
multi_constraint_method = info.optimization.run_options.multi_constraint_method
parameter_updater = parameter_table


space_index = 1

p_indices = eachindex(1:parameter_set_size)
@time cost_samples_q = qbmap(p_indices) do parameter_index 
    idx = Threads.threadid()
    parameter_vector = parameter_samples[:, parameter_index]
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, info.models.forward)
    coreTEM!(updated_models, run_helpers.space_forcing[space_index], run_helpers.space_spinup_forcing[space_index], run_helpers.loc_forcing_t, run_helpers.space_output_mt[idx], run_helpers.space_land[space_index], run_helpers.tem_info)
    cost_vector = metricVector(run_helpers.space_output_mt[idx], obs_array, cost_options)
    cost_metric = combineMetric(cost_vector, multi_constraint_method)
    # cost_samples_t[parameter_index] = cost_metric
    @info "qbmap: idx: $(idx), parameter_index: $(parameter_index), cost: $(cost_metric)"
    cost_metric
end

@time Threads.@threads for parameter_index in eachindex(1:parameter_set_size)
    idx = Threads.threadid()
    parameter_vector = parameter_samples[:, parameter_index]
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, info.models.forward)
    coreTEM!(updated_models, run_helpers.space_forcing[space_index], run_helpers.space_spinup_forcing[space_index], run_helpers.loc_forcing_t, run_helpers.space_output_mt[idx], run_helpers.space_land[space_index], run_helpers.tem_info)
    cost_vector = metricVector(run_helpers.space_output_mt[idx], obs_array, cost_options)
    cost_metric = combineMetric(cost_vector, multi_constraint_method)
    cost_samples_t[parameter_index] = cost_metric
    @info "@threads: idx: $(idx), parameter_index: $(parameter_index), cost: $(cost_metric)"
end

parameter_indices = 1:parameter_set_size

@sync begin
    for idx in eachindex(parameter_indices)
        Threads.@spawn begin
            parameter_index = parameter_indices[idx]
            parameter_vector = parameter_samples[:, parameter_index]
            updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, info.models.forward)
            coreTEM!(updated_models, run_helpers.space_forcing[space_index], run_helpers.space_spinup_forcing[space_index], run_helpers.loc_forcing_t, run_helpers.space_output_mt[parameter_index], run_helpers.space_land[space_index], run_helpers.tem_info)
            cost_vector = metricVector(run_helpers.space_output_mt[parameter_index], obs_array, cost_options)
            cost_metric = combineMetric(cost_vector, multi_constraint_method)
            @info "@spawn: idx: $(idx), parameter_index: $(parameter_index), cost: $(cost_metric)"
            cost_samples_s[parameter_index] = cost_metric
        end
    end
end


@time cost(parameter_samples, defaults, info.models.forward, run_helpers.space_forcing[space_index], run_helpers.space_spinup_forcing[space_index], run_helpers.loc_forcing_t, run_helpers.output_array, run_helpers.space_output_mt, run_helpers.space_land[space_index], run_helpers.tem_info, obs_array, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type, cost_samples_c,  CostModelObsMT())
for idx in eachindex(cost_samples_c) 
    cost_metric = cost_samples_c[idx]
    @info "@costfunction: idx: $(idx), cost: $(cost_metric)"
    idx += 1
end



fig=plot(cost_samples_t, label="threads loop : diff-threads = $(sum(cost_samples_t - cost_samples_t))", size=(2000, 1000))
plot!(cost_samples_c, label="threaded cost : diff-threads = $(sum(cost_samples_t - cost_samples_c))")
plot!(cost_samples_q, label="qbmap cost : diff-threads = $(sum(cost_samples_t - cost_samples_q))")
plot!(cost_samples_s, label="spawn cost : diff-threads = $(sum(cost_samples_t - cost_samples_s))")

cost_samples_t - cost_samples_c |> sum

do_serial = true
# do_serial = false
if do_serial
    @time for parameter_index in parameter_indices
        idx = parameter_index
        parameter_vector = parameter_samples[:, parameter_index]
        updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, info.models.forward)
        coreTEM!(updated_models, run_helpers.space_forcing[space_index], run_helpers.space_spinup_forcing[space_index], run_helpers.loc_forcing_t, run_helpers.space_output_mt[idx], run_helpers.space_land[space_index], run_helpers.tem_info)
        cost_vector = metricVector(run_helpers.space_output_mt[idx], obs_array, cost_options)
        cost_metric = combineMetric(cost_vector, multi_constraint_method)
        cost_samples_b[parameter_index] = cost_metric
        @info "serial: idx: $(idx), parameter_index: $(parameter_index), cost: $(cost_metric)"
    end
    plot!(cost_samples_b, label="serial cost : diff-threads = $(sum(cost_samples_t - cost_samples_b))")
end
savefig(joinpath(info.output.dirs.figure, "comparison_threads_$(parameter_set_size).png"))

fig