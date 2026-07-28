using Revise
@time using Sindbad
using Plots

toggle_type_abbrev_in_stacktrace()
domain = "africa_full_parameters";
optimize_it = true;
# optimize_it = false;
include("graf_models.jl");

replace_info_spatial = Dict("experiment.basics.domain" => domain * "_spatial",
    "experiment.basics.config_files.forcing" => "forcing_full_2d.json",
    "experiment.basics.config_files.parameters" => "/Net/Groups/BGI/scratch/skoirala/RnD/SINDBAD-RnD-SK/examples/exp_graf/output_africa_spatial_OptimDomain/optimization/OptimDomain_africa_spatial_model_parameters_to_optimize.csv",
    "experiment.basics.config_files.optimization" => "optimization_full_2d.json",
    "experiment.flags.run_optimization" => false,
    "experiment.flags.calc_cost" => true,
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
observations = getObservation(info, forcing.helpers);
obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because view of keyedarray is slow
parameter_table = info.optimization.parameter_table;

GC.gc()
info = drop_namedtuple_fields(info, (:settings,));
@time run_helpers = prepTEM(forcing, info);
# forcing = nothing


@time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)

for x ∈ 1:10
    @time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
end

@time spinupTEM(info.models.forward, run_helpers.space_spinup_forcing[1], run_helpers.loc_forcing_t, run_helpers.space_land[1], run_helpers.tem_info, run_helpers.tem_info.run.spinup_TEM);

# set_log_level(:debug)

@time output_cost = runExperimentCost(experiment_json; replace_info=replace_info_spatial);

# return (; forcing, info, loss=loss_vector, observation=obs_array, output=forward_output)


ds = forcing.data[1];
# plotdat = output_cost.output.optimized;
plotdat = output_cost.output;
default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
output_vars = keys(plotdat)
for i ∈ eachindex(output_vars)
    v = output_vars[i]
    # vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
    vname = v
    # vname = vinfo["standard_name"]
    println("plot output-model => domain: $domain, variable: $vname")
    pd = plotdat[i]
    if size(pd, 2) == 1
        heatmap(pd[:, 1, :]; title="$(vname)" , size=(2000, 1000))
        # Colorbar(fig[1, 2], obj)
        savefig(joinpath(info.output.dirs.figure, "$(domain)_$(vname).png"))
    else
        foreach(axes(pd, 2)) do ll
            heatmap(pd[:, ll, :]; title="$(vname)" , size=(2000, 1000))
            # Colorbar(fig[1, 2], obj)
            savefig(joinpath(info.output.dirs.figure, "$(domain)_$(vname)_$(ll).png"))
        end
    end
end

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
#set_log_level(:debug)
# @profview metricVector(run_helpers.output_array, obs_array, cost_options) # |> sum
# set
# @time metricVector(run_helpers.output_array, obs_array, cost_options) # |> sum


obs_array = output_cost.observation;
info = output_cost.info;

# some plots
opt_dat = output_cost.output.optimized;
def_dat = output_cost.output.default;
costOpt = prepCostOptions(obs_array, info.optimization.cost_options)
# ──────────────────────────────────────────────────
#  1 │ gpp                 NSEInv()    0.193419  1.54357
#  2 │ gpp_anom            NSEInv()    0.313791  0.55399
#  3 │ runoff              Pcor2Inv()  0.562564  0.586841
#  4 │ evapotranspiration  NSEInv()    0.589038  1.04692
#  5 │ tws                 NSEInv()    0.602671  0.805431

# {'gpp'      }    {'mefinv'}    0.17066
#     {'tws'      }    {'mefinv'}    0.55399
#     {'evapTotal'}    {'mefinv'}    0.35353 
#     {'runoff'   }    {'r2inv' }    0.55273
var_row = costOpt[1]
# using CairoMakie

losses = map(costOpt) do var_row
    v = var_row.variable
    v_key = v
    v = (var_row.mod_field, var_row.mod_subfield)
    vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
    v = vinfo["standard_name"]
    lossMetric = var_row.cost_metric
    loss_name = nameof(typeof(lossMetric))
    if loss_name in (:NNSEInv, :NSEInv)
        lossMetric = NSE()
    else
        lossMetric = Pcor2()
    end
    (obs_var, obs_σ, def_var) = getData(def_dat, obs_array, var_row);
    (_, _, opt_var) = getData(opt_dat, obs_array, var_row);

    (obs_var_no_nan, obs_σ_no_nan, def_var_no_nan) = getDataWithoutNaN(obs_var, obs_σ, def_var);
    (obs_var_no_nan, obs_σ_no_nan, opt_var_no_nan) = getDataWithoutNaN(obs_var, obs_σ, opt_var);

    loss_space = map([run_helpers.space_ind...]) do lsi
        opt_pix = view_at_trailing_indices(opt_var, lsi)
        def_pix = view_at_trailing_indices(def_var, lsi)
        obs_pix = view_at_trailing_indices(obs_var, lsi)
        obs_σ_pix = view_at_trailing_indices(obs_σ, lsi)
        (obs_pix_no_nan, obs_σ_pix_no_nan, opt_pix_no_nan) = getDataWithoutNaN(obs_pix, obs_σ_pix, opt_pix)
        (_, _, def_pix_no_nan) = getDataWithoutNaN(obs_pix, obs_σ_pix, def_pix)
        [metric(lossMetric, def_pix_no_nan, obs_pix_no_nan, obs_σ_pix_no_nan), metric(lossMetric, opt_pix_no_nan, obs_pix_no_nan, obs_σ_pix_no_nan)]
    end


    default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
    b_range = range(-1, 1, length=50)
    p_title = "$(var_row.variable) ($(nameof(typeof(lossMetric))))"
    histogram(first.(loss_space); title=p_title, size=(2000, 1000),bins=b_range, alpha=0.9, label="default", color="#FDB311")
    vline!([metric(lossMetric, def_var_no_nan, obs_var_no_nan, obs_σ_no_nan)], label="default_spatial", color="#FDB311", lw=3)
    histogram!(last.(loss_space); size=(2000, 1000), bins=b_range, alpha=0.5, label="optimized", color="#18A15C")
    vline!([metric(lossMetric, opt_var_no_nan, obs_var_no_nan, obs_σ_no_nan)], label="optimized_spatial", color="#18A15C", lw=3)
    xlabel!("")
    savefig(joinpath(info.output.dirs.figure, "obs_vs_pred_$(v_key).png"))
end
