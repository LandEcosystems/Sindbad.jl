using Revise
@time using Sindbad
using Plots

toggle_type_abbrev_in_stacktrace()
domain = "africa";
optimize_it = true;
# optimize_it = false;
include("graf_models.jl");

replace_info_spatial = Dict("experiment.basics.domain" => domain * "_spatial",
    "experiment.basics.config_files.forcing" => "forcing.json",
    "experiment.flags.run_optimization" => optimize_it,
    "experiment.flags.calc_cost" => optimize_it,
    "experiment.flags.catch_model_errors" => true,
    "experiment.flags.spinup_TEM" => true,
    "experiment.flags.debug_model" => false,
    # "optimization.optimization_cost_method" => "CostModelObsMT",
    # "optimization.optimization_cost_threaded"  => true,
    "model_structure.sindbad_models" => graf_models
    );

experiment_json = "../exp_graf/settings_graf/experiment.json";

info = getExperimentInfo(experiment_json; replace_info=replace_info_spatial); # note that this will modify information from json with the replace_info
forcing = getForcing(info);
info = drop_namedtuple_fields(info, (:settings,));
@time run_helpers = prepTEM(forcing, info);
# forcing = nothing


@time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
