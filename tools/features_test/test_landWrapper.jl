using Revise
using Sindbad

toggle_type_abbrev_in_stacktrace()
experiment_json = "../../examples/setups/WROASTED/experiment.json"
begin_year = "1979"
end_year = "2017"

domain = "DE-Hai"
# domain = "MY-PSO"
path_input = "$(getSindbadDataDepot())/fn/$(domain).1979.2017.daily.nc"
forcing_config = "forcing.json"

path_observation = path_input
optimize_it = true
optimize_it = false
path_output = nothing


parallelization_lib = "threads"
model_array_type = "static_array"
replace_info = Dict("experiment.basics.time.date_begin" => begin_year * "-01-01",
    "experiment.basics.config_files.forcing" => forcing_config,
    "experiment.basics.domain" => domain,
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
    "optimization.algorithm_optimization" => "CMAEvolutionStrategy_CMAES.json",
    "optimization.observations.default_observation.data_path" => path_observation);

info = getExperimentInfo(experiment_json; replace_info=replace_info); # note that this will modify information from json with the replace_info

forcing = getForcing(info);

# calculate the losses
observations = getObservation(info, forcing.helpers);
obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because view of keyedarray is slow

info = drop_namedtuple_fields(info, (:settings,));

run_helpers = prepTEM(forcing, info);

@time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)

@time land_stacked_ts = runTEM(info.models.forward, run_helpers.space_forcing[1], run_helpers.space_spinup_forcing[1], run_helpers.loc_forcing_t, deepcopy(run_helpers.loc_land), run_helpers.tem_info);

land_stacked_prealloc = Vector{typeof(run_helpers.loc_land)}(undef, info.helpers.dates.size);

@time land_stacked_prealloc = runTEM(info.models.forward, run_helpers.space_forcing[1], run_helpers.space_spinup_forcing[1], run_helpers.loc_forcing_t, land_stacked_prealloc, run_helpers.loc_land, run_helpers.tem_info);
runTEM(info.models.forward, run_helpers.space_forcing[1], run_helpers.space_spinup_forcing[1], run_helpers.loc_forcing_t, land_stacked_prealloc, run_helpers.loc_land, run_helpers.tem_info);

parameter_table = info.optimization.parameter_table;


cost_options = prepCostOptions(obs_array, info.optimization.cost_options);

@time metricVector(run_helpers.output_array, obs_array, cost_options)  |> sum
@time metricVector(land_stacked_ts, obs_array, cost_options)  |> sum
@time metricVector(land_stacked_prealloc, obs_array, cost_options) |> sum


parameter_table = info.optimization.parameter_table;
defaults = parameter_table.initial;

@time cost(defaults, defaults, info.models.forward, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.output_array, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info, obs_array, parameter_table, cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling, info.optimization.run_options.cost_method)

@time costLand(defaults, info.models.forward, run_helpers.space_forcing[1], run_helpers.space_spinup_forcing[1], run_helpers.loc_forcing_t, nothing, run_helpers.loc_land, run_helpers.tem_info, obs_array, parameter_table, cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling)

@time costLand(defaults, info.models.forward, run_helpers.space_forcing[1], run_helpers.space_spinup_forcing[1], run_helpers.loc_forcing_t, land_stacked_prealloc, run_helpers.loc_land, run_helpers.tem_info, obs_array, parameter_table, cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling)