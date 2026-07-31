using Revise
using SindbadTEM
using Sindbad
using Plots
using Plots: cm

toggle_type_abbrev_in_stacktrace()
experiment_json = "../../examples/setups/WROASTED/experiment.json"

# NOTE: hourly synthetic data is not published yet -- forcing_hourly.json's data_path is a
# placeholder (https://s3.bgc-jena.mpg.de:9000/sindbad/synthetic_data_examples_hourly.zarr)
# pointing at a dataset that doesn't exist yet. begin_year/end_year and forcing_hourly.json's
# variable mapping are carried over from the old site-level setup as a starting point and will
# need revisiting once the real cube (and its variable/site layout) is available.
begin_year = "1999"
end_year = "2010"

site_index = 1
optimize_it = false
path_output = nothing

parallelization_lib = "threads"
model_array_type = "static_array"
replace_info = Dict("experiment.basics.time.date_begin" => begin_year * "-01-01",
    "experiment.basics.config_files.forcing" => joinpath(@__DIR__, "forcing_hourly.json"),
    "experiment.basics.name" => "WROASTED_hour",
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
    "optimization.algorithm_optimization" => "CMAEvolutionStrategy_CMAES.json")

info = getExperimentInfo(experiment_json; replace_info=replace_info); # note that this will modify information from json with the replace_info

parameter_table = info.optimization.parameter_table;

forcing = getForcing(info);

run_helpers = prepTEM(forcing, info);
@time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info);

@time output_all = runExperimentFullOutput(experiment_json; replace_info=replace_info);
output_data = values(output_all.output)
info = output_all.info
output_vars = info.output.variables
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

default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
forc_vars = forcing.variables
for (o, v) in enumerate(forc_vars)
    println("plot forc-model => domain: $(info.experiment.basics.domain), variable: $v")
    def_var = forcing.data[o]
    plot_data = nothing
    xdata = [info.helpers.dates.range...]
    if size(def_var, 1) !== length(xdata)
        xdata = 1:size(def_var, 1)
        plot_data = def_var[:, 1, 1]
        # plot_data = reshape(plot_data, (1,length(plot_data)))
    else
        plot_data = def_var[:, 1, 1]
    end
    plot(xdata, plot_data; title="$(v):: mean = $(round(SindbadTEM.mean(plot_data), digits=2)), nans=$(sum(isnan.(plot_data)))", size=(2000, 1000))
    savefig(fig_prefix * "_forc_$(v).png")
end
