using Revise
using SindbadTEM
using Sindbad
using Plots

toggle_type_abbrev_in_stacktrace()
experiment_json = "../exp_WROASTED/settings_WROASTED/experiment.json"
begin_year = "1999"
end_year = "2010"

domain = "CA-Obs"
path_input = nothing
forcing_config = nothing
optimization_config = nothing
mod_step = "day"
# mod_step = "hour"
# foreach(["day", "hour"]) do mod_step
if mod_step == "day"
    path_input = "$(getSindbadDataDepot())/fn/$(domain).1979.2017.daily.nc"
    forcing_config = "forcing_erai.json"
    optimization_config = "optimization.json"
else
    mod_step
    path_input = "$(getSindbadDataDepot())/fn/$(domain).1999.2010.hourly_for_Sindbad.nc"
    forcing_config = "forcing_hourly.json"
    optimization_config = "optimization_hourly.json"
end

path_observation = path_input
optimize_it = false
optimize_it = true
path_output = nothing

set_log_level(:info)

parallelization_lib = "threads"
model_array_type = "static_array"
replace_info = Dict("experiment.basics.time.date_begin" => begin_year * "-01-01",
    "experiment.basics.config_files.forcing" => forcing_config,
    "experiment.basics.config_files.optimization" => optimization_config,
    "experiment.basics.domain" => domain,
    "experiment.basics.name" => "WROASTED_$mod_step",
    "experiment.basics.time.temporal_resolution" => mod_step,
    "forcing.default_forcing.data_path" => path_input,
    "experiment.basics.time.date_end" => end_year * "-12-31",
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
    "optimization.algorithm_optimization" => "opti_algorithms/CMAEvolutionStrategy_CMAES_mt_test.json",
    "optimization.optimization_cost_method" => "CostModelObsMT",
    "optimization.optimization_cost_threaded"  => true,
    "optimization.subset_model_output" => false,
    "optimization.observations.default_observation.data_path" => path_observation)

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