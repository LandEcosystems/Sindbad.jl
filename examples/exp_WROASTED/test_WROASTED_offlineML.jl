using Revise
using Sindbad
using CMAEvolutionStrategy
# Simulation
# using CairoMakie


toggle_type_abbrev_in_stacktrace()
experiment_json = "/Net/Groups/BGI/scratch/relghawi/Sinbad_test/Sindbad-Dev/settings_WROASTED/experiment.json"
begin_year = "2000"
end_year = "2017"

domain = "DE-Hai"
# domain = "MY-PSO"
path_input = "/Net/Groups/BGI/scratch/relghawi/Sinbad_test/Sindbad-Dev/DE-Hai.1979.2017.daily.nc"
# path_input  = "/Net/Groups/BGI/scratch/skoirala/RnD/SINDBAD-RnD-SK/examples/data/fn/US-SRM.1979.2017.daily.nc"
forcing_config = "/Net/Groups/BGI/scratch/relghawi/Sinbad_test/Sindbad-Dev/settings_WROASTED/forcing_erai.json"

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
    "experiment.exe_rules.model_array_type" => model_array_type,
    "experiment.model_output.path" => path_output,
    "experiment.model_output.format" => "nc",
    "experiment.model_output.save_single_file" => true,
    "experiment.exe_rules.parallelization" => parallelization_lib,
    "optimization.algorithm_optimization" => "opti_algorithms/CMAEvolutionStrategy_CMAES.json",
    "optimization.observations.default_observation.data_path" => path_observation);

info = getExperimentInfo(experiment_json; replace_info=replace_info); # note that this will modify information from json with the replace_info
forcing = getForcing(info);
run_helpers = prepTEM(forcing, info);
@time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)

@time output_default = runExperimentForward(experiment_json; replace_info=replace_info);
@time output_cost = runExperimentCost(experiment_json; replace_info=replace_info);
@time out_opti = runExperimentOpti(experiment_json; replace_info=replace_info);

observation = out_opti.observation

# some plots
def_dat = out_opti.output.default;
opt_dat = out_opti.output.optimized;
costOpt = prepCostOptions(observation, info.optimization.cost_options);
plots_default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
foreach(costOpt) do var_row
    v = var_row.variable
    println("plot obs::", v)
    v = (var_row.mod_field, var_row.mod_subfield)
    vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
    v = vinfo["standard_name"]
    lossMetric = var_row.cost_metric
    loss_name = nameof(typeof(lossMetric))
    if loss_name in (:NNSEInv, :NSEInv)
        lossMetric = NSE()
    # else
        # lossMetric = Pcor()    
    end
    (obs_var, obs_σ, def_var) = getData(def_dat, observation, var_row)
    (_, _, opt_var) = getData(opt_dat, observation, var_row)
    obs_var_TMP = obs_var[:, 1, 1, 1]
    non_nan_index = findall(x -> !isnan(x), obs_var_TMP)
    if length(non_nan_index) < 2
        tspan = 1:length(obs_var_TMP)
    else
        tspan = first(non_nan_index):last(non_nan_index)
    end
    obs_σ = obs_σ[tspan]
    obs_var = obs_var[tspan, 1, 1, 1]
    def_var = def_var[tspan, 1, 1, 1]
    opt_var = opt_var[tspan, 1, 1, 1]

    xdata = [info.helpers.dates.range[tspan]...]
    obs_var_n, obs_σ_n, def_var_n = getDataWithoutNaN(obs_var, obs_σ, def_var)
    obs_var_n, obs_σ_n, opt_var_n = getDataWithoutNaN(obs_var, obs_σ, opt_var)
    metr_def = metric(lossMetric, def_var_n, obs_var_n, obs_σ_n)
    metr_opt = metric(lossMetric, opt_var_n, obs_var_n, obs_σ_n)
    plots_plot(xdata, obs_var; label="obs", seriestype=:scatter, mc=:black, ms=4, lw=0, ma=0.65, left_margin=1plots_cm)
    plots_plot!(xdata, def_var, color=:steelblue2, lw=1.5, ls=:dash, left_margin=1plots_cm, legend=:outerbottom, legendcolumns=3, label="def ($(round(metr_def, digits=2)))", size=(2000, 1000), title="$(vinfo["long_name"]) ($(vinfo["units"])) -> $(nameof(typeof(lossMetric)))")
    plots_plot!(xdata, opt_var; color=:seagreen3, label="opt ($(round(metr_opt, digits=2)))", lw=1.5, ls=:dash)
    plots_savefig(joinpath(info.output.dirs.figure, "wroasted_$(domain)_$(v).png"))
end
