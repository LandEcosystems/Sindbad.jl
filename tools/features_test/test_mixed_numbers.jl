using Revise
using SindbadTEM
using Sindbad

toggle_type_abbrev_in_stacktrace()
experiment_json = "../../examples/setups/WROASTED/experiment.json"

site_index = 1
optimize_it = true
# optimize_it = false
path_output = nothing

parallelization_lib = "threads"
model_array_type = "static_array"
replace_info = Dict("experiment.basics.domain" => "test_mixed_numbers",
    "forcing.subset.site" => [site_index],
    "experiment.flags.run_optimization" => optimize_it,
    "experiment.flags.calc_cost" => true,
    "experiment.flags.catch_model_errors" => false,
    "experiment.flags.spinup_TEM" => true,
    "experiment.flags.debug_model" => false,
    "experiment.exe_rules.model_array_type" => model_array_type,
    "experiment.model_output.path" => path_output,
    "experiment.model_output.format" => "nc",
    "experiment.model_output.save_single_file" => true,
    "experiment.exe_rules.parallelization" => parallelization_lib,
    "optimization.algorithm_optimization" => "CMAEvolutionStrategy_CMAES.json");

info = getExperimentInfo(experiment_json; replace_info=replace_info); # note that this will modify information from json with the replace_info

parameter_table = info.optimization.parameter_table;

forcing = getForcing(info);

run_helpers = prepTEM(forcing, info);

@time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)


optimized_models = info.models.forward;
parameter_table = info.optimization.parameter_table;
selected_models = info.models.forward;

rand_m = rand()
# parameter_vector = parameter_table.initial .* info.helpers.numbers.num_type(rand_m);
parameter_vector = parameter_table.initial .* rand_m;
@time selected_models = updateModelParameters(parameter_table, info.models.forward, parameter_vector);

parameter_vector = ForwardDiff.Dual.(parameter_table.initial .* rand_m);

n_m = updateModelParameters(parameter_table, info.models.forward, parameter_vector);
run_helpers_s = prepTEM(selected_models, forcing, info);
@time runTEM!(selected_models,
    run_helpers_s.space_forcing,
    run_helpers_s.space_spinup_forcing,
    run_helpers_s.loc_forcing_t,
    run_helpers_s.space_output,
    run_helpers_s.space_land,
    run_helpers_s.tem_info)

run_helpers_n = prepTEM(n_m, forcing, info);
@time runTEM!(n_m,
    run_helpers_n.space_forcing,
    run_helpers_n.space_spinup_forcing,
    run_helpers_n.loc_forcing_t,
    run_helpers_n.space_output,
    run_helpers_n.space_land,
    run_helpers_n.tem_info)

@time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
