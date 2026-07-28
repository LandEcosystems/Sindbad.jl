using Revise
using Sindbad
using Plots
# using CairoMakie


toggle_type_abbrev_in_stacktrace()
experiment_json = "../exp_OTB/settings_OTB/experiment.json"
begin_year = "1979"
end_year = "2017"

domain = "US-SRM"
# domain = "MY-PSO"
path_input = "$(getSindbadDataDepot())/fn/$(domain).1979.2017.daily.nc"
forcing_config = "forcing_erai.json"

path_observation = path_input
optimize_it = true
# optimize_it = false
path_output = nothing

parallelization_lib = "threads"
model_array_type = "static_array"
replace_info = Dict("experiment.basics.time.date_begin" => begin_year * "-01-01",
    "experiment.basics.config_files.forcing" => forcing_config,
    "experiment.basics.domain" => domain,
    "forcing.default_forcing.data_path" => path_input,
    "experiment.basics.time.date_end" => end_year * "-12-31",
    "experiment.flags.run_optimization" => optimize_it,
    "experiment.flags.calc_cost" => false,
    "experiment.flags.catch_model_errors" => false,
    "experiment.flags.spinup_TEM" => true,
    "experiment.flags.debug_model" => false,
    "experiment.exe_rules.model_number_type" => "Float64",
    "experiment.exe_rules.model_array_type" => model_array_type,
    "experiment.model_output.path" => path_output,
    "experiment.model_output.format" => "nc",
    "experiment.model_output.save_single_file" => true,
    "experiment.exe_rules.parallelization" => parallelization_lib,
    "optimization.algorithm" => "opti_algorithms/Optim_LBFGS.json",
    "optimization.observations.default_observation.data_path" => path_observation);

# info = getExperimentInfo(experiment_json; replace_info=replace_info); # note that this will modify information from json with the replace_info
# forcing = getForcing(info);
# run_helpers = prepTEM(forcing, info);
# @time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)

# @time output_default = runExperimentForward(experiment_json; replace_info=replace_info);

# parameter_table = info.optimization.parameter_table;




# loss_vector = getLossVector(fp_output.output.optimized, opti_output.observation, cost_options)


# # current
# x0 = def
# lb = lb
# ub = ub

# # scale to default
# x0 = def/def
# lb =lb/def
# ub = ub/def

# p0, p1 ∈ [0, 100000]
# def0 = 10000, def1 = 1
# p0 -> [0, 1, 10]
# p1 -> [0, 1, 100000]

# # scale to 0-1
# lb = 0
# ub = 1
# scalar_def = def - lb  / (ub - lb) 
# x0 = lb + (ub - lb) * scalar_def
# param = lb + (ub - lb) * scalar


# parameter_table = info.optimization.parameter_table;


# @time output_cost = runExperimentCost(experiment_json; replace_info=replace_info);

@time out_synthetic = runExperimentSyntheticOpti(experiment_json; replace_info=replace_info);

@time out_opti = runExperimentOpti(experiment_json; replace_info=replace_info);

# some plots
# NOTE: behavior change vs. the original inline code: this script previously computed
# the loss via `loss(...)`/`filterCommonNaN(...)`, whereas plotTimeSeries's shared
# helper uses `metric(...)`/`getDataWithoutNaN(...)` - verify these produce equivalent
# results for this experiment's cost metrics before relying on the reported values.
plotTimeSeries(out_opti)
