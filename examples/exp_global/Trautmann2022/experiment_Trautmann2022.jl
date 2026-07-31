using Revise
@time using Sindbad
using Plots

toggle_type_abbrev_in_stacktrace()
domain = "Global";
optimize_it = true;
# optimize_it = false;

include("Trautmann2022_models.jl");

replace_info_spatial = Dict("experiment.basics.domain" => domain * "_spatial",
    "experiment.basics.config_files.forcing" => "forcing.json",
    "experiment.flags.run_optimization" => optimize_it,
    "experiment.flags.calc_cost" => true,
    "experiment.flags.spinup_TEM" => true,
    "experiment.flags.debug_model" => false,
    "model_structure.sindbad_models" => Trautmann2022_models
    );

experiment_json = "settings_Trautmann2022/experiment.json";

info = getExperimentInfo(experiment_json; replace_info=replace_info_spatial); # note that this will modify information from json with the replace_info
forcing = getForcing(info);

observations = getObservation(info, forcing.helpers);
obs_array = [Array(_o) for _o in observations.data]; # TODO: 

GC.gc()

run_helpers = prepTEM(forcing, info);

@time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)

for x ∈ 1:10
    @time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
end


tbl_params = info.optimization.parameter_table;


cost_options = prepCostOptions(obs_array, info.optimization.cost_options)

@time metricVector(run_helpers.output_array, obs_array, cost_options) # |> sum

@time out_opti = runExperimentOpti(experiment_json; replace_info=replace_info_spatial);

obs_array = out_opti.observation;
info = out_opti.info;

# some plots
# NOTE: behavior change vs. the original inline code: plotPerformanceHistograms only
# substitutes NSE() for NNSEInv/NSEInv metrics; it does NOT fall back to Pcor2() for
# other metrics the way this script previously did.
plotPerformanceHistograms(out_opti)

default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
forc_vars = forcing.variables
for (o, v) in enumerate(forc_vars)
    println("plot forc-model => domain: $domain, variable: $v")
    def_var = forcing.data[o]
    plot_data=nothing
    xdata = [info.helpers.dates.range...]
    if size(def_var, 1) !== length(xdata)
        xdata = 1:size(def_var, 1)
        plot_data =  def_var[:]
        plot_data = reshape(plot_data, (1,length(plot_data)))
    else
        plot_data =  def_var[:,:]
    end
    heatmap(plot_data; title="$(v):: mean = $(round(SindbadTEM.mean(def_var), digits=2)), nans=$(sum(is_invalid_number.(plot_data)))", size=(2000, 1000))
    savefig(joinpath(info.output.dirs.figure, "forc_$(domain)_$v.png"))
end

# @time output_cost = runExperimentCost(experiment_json; replace_info=replace_info_spatial);  

# @time output_default = runExperimentForward(experiment_json; replace_info=replace_info_spatial);

@time output_all = runExperimentFullOutput(experiment_json; replace_info=replace_info_spatial);

ds = forcing.data[1];

plotdat = run_helpers.output_array;
output_vars = val_to_symbol(run_helpers.tem_info.vals.output_vars)

plotdat = output_all.output;
output_vars = output_all.info.output.variables;

default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
for i ∈ eachindex(output_vars)
    v = output_vars[i]
    vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
    vname = vinfo["standard_name"]
    println("plot output-model => domain: $domain, variable: $vname")
    pd = plotdat[i]
    if size(pd, 2) == 1
        heatmap(pd[:, 1, :]; title="$(vname)" , size=(2000, 1000))
        # Colorbar(fig[1, 2], obj)
        savefig(joinpath(info.output.dirs.figure, "glob_$(vname).png"))
    else
        foreach(axes(pd, 2)) do ll
            heatmap(pd[:, ll, :]; title="$(vname)" , size=(2000, 1000))
            # Colorbar(fig[1, 2], obj)
            savefig(joinpath(info.output.dirs.figure, "glob_$(vname)_$(ll).png"))
        end
    end
end
