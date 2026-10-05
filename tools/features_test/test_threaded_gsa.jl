using Revise
using SindbadTEM
using Sindbad
using Plots

using QuasiMonteCarlo
using GlobalSensitivity
using StableRNGs
toggle_type_abbrev_in_stacktrace()
experiment_json = "../../examples/setups/WROASTED/experiment.json"

site_index = 1
optimize_it = true
path_output = nothing

set_log_level(:info)

parallelization_lib = "threads"
model_array_type = "static_array"
replace_info = Dict("experiment.basics.name" => "WROASTED_threaded_gsa",
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
    "optimization.algorithm_sensitivity_analysis" => joinpath(@__DIR__, "sa_methods", "GSA_SobolDM.json"),
    "optimization.subset_model_output" => false,
    "optimization.optimization_cost_method" => "CostModelObsMT",
    "optimization.optimization_cost_threaded"  => true)


out_sensitivity = runExperimentSensitivity(experiment_json; replace_info=replace_info, log_level=:info);
info = out_sensitivity.info;
parameter_names=String.(out_sensitivity.parameter_table.name);

sa_method = nameof(typeof(info.optimization.sensitivity_analysis.method))
if sa_method in (:GSASobol, :GSASobolDM)
    sobol_result = out_sensitivity.sensitivity;
    xt=1:length(parameter_names)
    pb = bar(xt, sobol_result.ST[:, :], label="Total",
        title = "Sobol Indices", legend = true, size=(2000, 1000), xticks=(xt, parameter_names), xrotation=90,fontsize=18,layout=(2,1))
    bar!(xt, sobol_result.S1[:, :], label="First", legend = true, size=(2000, 1000), xticks=(xt, parameter_names), xrotation=90,fontsize=18, subplot=2)
    savefig(joinpath(info.output.dirs.figure, "GSA_$(sa_method)_S1-ST_$(info.experiment.basics.domain)_$(length(out_sensitivity.cost_vector))-cost_evals.png"))
    s2=deepcopy(sobol_result.S2)
    s2[s2.==0] .= NaN
    ph=heatmap(s2; title="S2" , size=(1500, 1500), xticks=(xt, parameter_names), xrotation=90,fontsize=18, yticks=(xt, parameter_names))
    savefig(joinpath(info.output.dirs.figure, "GSA_$(sa_method)_S2_$(info.experiment.basics.domain)_$(length(out_sensitivity.cost_vector))-cost_evals.png"))    
end

if sa_method in (:GSAMorris, )
    morris_result = out_sensitivity.sensitivity;
    xt=1:length(parameter_names)
    ps=scatter(morris_result.means[1, :], morris_result.variances[1, :], series_annotations = parameter_names, color = :gray, size=(2000, 1000))
    savefig(joinpath(info.output.dirs.figure, "GSA_$(sa_method)_scatter_$(info.experiment.basics.domain)_$(length(out_sensitivity.cost_vector))-cost_evals.png"))    
    pb = bar(xt, morris_result.means[1, :], label="Means",
        title = "Morris Means", legend = true, size=(2000, 1000), xticks=(xt, parameter_names), xrotation=90,fontsize=18,layout=(2,1))
    bar!(xt, morris_result.variances[1, :], label="Variances",
        title = "Morris Variances", legend = true, size=(2000, 1000), xticks=(xt, parameter_names), xrotation=90,fontsize=18,subplot=2)
    savefig(joinpath(info.output.dirs.figure, "GSA_$(sa_method)_bar_$(info.experiment.basics.domain)_$(length(out_sensitivity.cost_vector))-cost_evals.png"))
end

# calls to look at inner objects in the experiment for dev purposes
info, forcing = prepExperiment(experiment_json; replace_info=replace_info);
observations = getObservation(info, forcing.helpers);

obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because view of keyedarray is slow

opti_helpers = prepOpti(forcing, obs_array, info, info.optimization.run_options.cost_method; algorithm_info_field=:sensitivity_analysis);

cost_function = opti_helpers.cost_function
p_bounds=Tuple.(Pair.(opti_helpers.lower_bounds,opti_helpers.upper_bounds));
method_options = info.optimization.sensitivity_analysis.options;

sampler = getproperty(Sindbad.ParameterOptimization.GlobalSensitivity, Symbol(method_options.sampler))(; method_options.sampler_options..., method_options.method_options... )
results = gsa(cost_function, sampler, p_bounds; method_options..., batch=true)

