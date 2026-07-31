using Revise
using Sindbad
using Plots
using Plots: cm

toggle_type_abbrev_in_stacktrace()
experiment_json = "../../examples/setups/WROASTED/experiment.json"

site_index = 1
# optimize_it = true
optimize_it = false
path_output = nothing

parallelization_lib = "threads"
model_array_type = "static_array"
replace_info = Dict("experiment.basics.name" => "WROASTED_output_all",
    "forcing.subset.site" => [site_index],
    "experiment.flags.run_optimization" => optimize_it,
    "experiment.flags.calc_cost" => false,
    "experiment.flags.catch_model_errors" => false,
    "experiment.flags.spinup_TEM" => true,
    "experiment.flags.debug_model" => false,
    "experiment.exe_rules.model_array_type" => model_array_type,
    "experiment.model_output.path" => path_output,
    "experiment.model_output.format" => "nc",
    "experiment.model_output.save_single_file" => false,
    "experiment.exe_rules.parallelization" => parallelization_lib,
    "optimization.algorithm_optimization" => "CMAEvolutionStrategy_CMAES.json");

@time output_all = runExperimentFullOutput(experiment_json; replace_info=replace_info);
output_data = values(output_all.output);
info = output_all.info;
output_vars = info.output.variables;
# plot the debug figures
default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
fig_prefix = joinpath(info.output.dirs.figure, "debug_" * info.experiment.basics.name * "_" * info.experiment.basics.domain)
for (o, v) in enumerate(output_vars)
    def_var = output_data[o][:, :, 1, 1]
    vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
    v = vinfo["standard_name"]
    println("plot debug::", v)
    xdata = [info.helpers.dates.range...]
    if size(def_var, 2) == 1
        plot(xdata, def_var[:, 1]; label="def ($(round(SindbadTEM.mean(def_var[:, 1]), digits=2)))", size=(2000, 1000), title="$(vinfo["long_name"]) ($(vinfo["units"]))", left_margin=1cm)
        ylabel!("$(vinfo["standard_name"])", font=(20, :green))
        savefig(fig_prefix * "_$(v).png")
    else
        foreach(axes(def_var, 2)) do ll
            plot(xdata, def_var[:, ll]; label="def ($(round(SindbadTEM.mean(def_var[:, ll]), digits=2)))", size=(2000, 1000), title="$(vinfo["long_name"]), layer $(ll),  ($(vinfo["units"]))", left_margin=1cm)
            ylabel!("$(vinfo["standard_name"])", font=(20, :green))
            savefig(fig_prefix * "_$(v)_$(ll).png")
        end
    end
end
