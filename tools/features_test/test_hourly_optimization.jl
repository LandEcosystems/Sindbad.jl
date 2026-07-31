using Revise
using SindbadTEM
using Sindbad
using Plots

toggle_type_abbrev_in_stacktrace()
experiment_json = "../../examples/setups/WROASTED/experiment.json"

# NOTE: hourly synthetic data is not published yet -- forcing_hourly.json/optimization_hourly.json's
# paths are placeholders (see forcing_hourly.json's data_path,
# https://s3.bgc-jena.mpg.de:9000/sindbad/synthetic_data_examples_hourly.zarr) pointing at a
# dataset that doesn't exist yet. begin_year/end_year and the hourly configs' variable mapping
# are carried over from the old site-level setup as a starting point and will need revisiting
# once the real cube (and its variable/site layout) is available.
begin_year = "1999"
end_year = "2010"

site_index = 1
optimize_it = true
path_output = nothing

set_log_level(:info)

parallelization_lib = "threads"
model_array_type = "static_array"
replace_info = Dict("experiment.basics.time.date_begin" => begin_year * "-01-01",
    "experiment.basics.config_files.forcing" => joinpath(@__DIR__, "forcing_hourly.json"),
    "experiment.basics.config_files.optimization" => joinpath(@__DIR__, "optimization_hourly.json"),
    "experiment.basics.name" => "WROASTED_hourly_optimization",
    "experiment.basics.time.temporal_resolution" => "hour",
    "experiment.basics.time.date_end" => end_year * "-12-31",
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
    "optimization.algorithm_optimization" => joinpath(@__DIR__, "opti_algorithms", "CMAEvolutionStrategy_CMAES_mt_test.json"),
    "optimization.optimization_cost_method" => "CostModelObsMT",
    "optimization.optimization_cost_threaded"  => true,
    "optimization.subset_model_output" => false)

info = getExperimentInfo(experiment_json; replace_info=replace_info); # note that this will modify information from json with the replace_info

parameter_table = info.optimization.parameter_table;

forcing = getForcing(info);

run_helpers = prepTEM(forcing, info);
@time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info);
# @time output_cost = runExperimentCost(experiment_json; replace_info=replace_info);

runExperimentForward(experiment_json; replace_info=replace_info);
# calculate the losses
observations = getObservation(info, forcing.helpers);
obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because view of keyedarray is slow
cost_options = prepCostOptions(obs_array, info.optimization.cost_options);

# set_log_level(:debug)
# @profview metricVector(run_helpers.output_array, obs_array, cost_options) # |> sum
# set
@time metricVector(run_helpers.output_array, obs_array, cost_options) # |> sum

@time out_opti = runExperimentOpti(experiment_json; replace_info=replace_info);

# some plots
plotTimeSeries(out_opti)
# end