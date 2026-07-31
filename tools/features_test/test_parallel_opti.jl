using Revise
using Sindbad
using CMAEvolutionStrategy
using Plots
# using CairoMakie


toggle_type_abbrev_in_stacktrace()
experiment_json = "../../examples/setups/WROASTED/experiment.json"

site_index = 1
optimize_it = true
# optimize_it = false
path_output = nothing

parallelization_lib = "threads"
model_array_type = "static_array"
replace_info = Dict("experiment.basics.name" => "WROASTED_parallel_opti",
    "forcing.subset.site" => [site_index],
    "experiment.flags.run_optimization" => optimize_it,
    "experiment.flags.calc_cost" => false,
    "experiment.flags.catch_model_errors" => false,
    "experiment.flags.spinup_TEM" => true,
    "experiment.flags.debug_model" => false,
    "experiment.exe_rules.model_array_type" => model_array_type,
    "experiment.model_output.path" => path_output,
    "experiment.model_output.format" => "nc",
    "experiment.model_output.save_single_file" => true,
    "experiment.exe_rules.parallelization" => parallelization_lib,
    "optimization.algorithm_optimization" => joinpath(@__DIR__, "opti_algorithms", "CMAEvolutionStrategy_CMAES_mt.json"),
    "optimization.optimization_cost_method" => "CostModelObsMT",
    "optimization.optimization_cost_threaded"  => true);

info = getExperimentInfo(experiment_json; replace_info=replace_info); # note that this will modify information from json with the replace_info
forcing = getForcing(info);
run_helpers = prepTEM(forcing, info);
@time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
# observations = getObservation(info, forcing.helpers);
# obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because 

# opti_helpers = prepOpti(forcing, obs_array, info, info.optimization.run_options.cost_method);

# @time output_default = runExperimentForward(experiment_json; replace_info=replace_info);
# @time output_cost = runExperimentCost(experiment_json; replace_info=replace_info);
@time out_opti = runExperimentOpti(experiment_json; replace_info=replace_info, log_level=:warn);

# some plots
plotTimeSeries(out_opti)
