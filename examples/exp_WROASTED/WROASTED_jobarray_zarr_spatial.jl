using Revise
using Sindbad
using Dates
using Plots

toggle_type_abbrev_in_stacktrace()

# site_index = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"])
site_index = 89
# site_index = Base.parse(Int, ARGS[1])
forcing_set = "erai"
site_info = CSV.File(
"/Net/Groups/BGI/scratch/skoirala/prod_sindbad.jl/examples/exp_WROASTED/settings_WROASTED/site_names_disturbance.csv";
    header=true);
domain = string(site_info[site_index][1])
y_dist = string(site_info[site_index][2])

experiment_json = "../exp_WROASTED/settings_WROASTED/experiment.json"
path_input = nothing
begin_year = nothing
end_year = nothing
ml_main_dir = nothing
if forcing_set == "erai"
    dataset = "ERAinterim.v2"
    begin_year = "1979"
    end_year = "2017"
    ml_main_dir = "/Net/Groups/BGI/scratch/skoirala/v202312_ml_wroasted/"
else
    dataset = "CRUJRA.v2_2"
    begin_year = "1901"
    end_year = "2019"
    ml_main_dir = "/Net/Groups/BGI/scratch/skoirala/cruj_sets_wroasted/"
end
ml_data_file = joinpath(ml_main_dir, "sindbad_processed_sets/set1/fluxnetBGI2021.BRK15.DD", dataset, "data", "$(domain).$(begin_year).$(end_year).daily.nc")
path_input = 
 "/Net/Groups/BGI/work_4/scratch/lalonso/FLUXNET_v2023_12_1D.zarr";#joinpath("/Net/Groups/BGI/scratch/skoirala/v202312_wroasted/fluxNet_0.04_CLIFF/fluxnetBGI2021.BRK15.DD/data", dataset, "daily/$(domain).$(begin_year).$(end_year).daily.nc");
 
path_observation = path_input;

nrepeat = 200

nrepeat_d = nothing
if y_dist != "undisturbed"
    y_disturb = year(Date(y_dist))
    y_start = Meta.parse(begin_year)
    nrepeat_d = y_start - y_disturb
end
sequence = nothing
if isnothing(nrepeat_d)
    sequence = [
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat),
        Dict("spinup_mode" => "eta_scale_AH", "forcing" => "day_MSC", "n_repeat" => 1),
    ]
elseif nrepeat_d < 0
    sequence = [
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat),
        Dict("spinup_mode" => "eta_scale_AH", "forcing" => "day_MSC", "n_repeat" => 1),
    ]
elseif nrepeat_d == 0
    sequence = [
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat),
        Dict("spinup_mode" => "eta_scale_A0H", "forcing" => "day_MSC", "n_repeat" => 1),
    ]
elseif nrepeat_d > 0
    sequence = [
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat),
        Dict("spinup_mode" => "eta_scale_A0H", "forcing" => "day_MSC", "n_repeat" => 1),
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat_d),
    ]
else
    error("cannot determine the repeat for disturbance")
end

opti_sets = Dict(
    :set1 => ["gpp", "nee", "reco", "transpiration", "evapotranspiration", "agb", "ndvi"],
    :set2 => ["gpp", "nee", "transpiration", "evapotranspiration", "agb", "ndvi"],
    :set3 => ["gpp", "nee", "reco", "transpiration", "evapotranspiration"],
    :set4 => ["gpp", "nee", "transpiration", "evapotranspiration"],
    :set5 => ["gpp", "nee", "reco", "evapotranspiration", "agb", "ndvi"],
    :set6 => ["gpp", "nee", "evapotranspiration", "agb", "ndvi"],
    :set7 => ["gpp", "evapotranspiration", "agb", "ndvi"],
    :set8 => ["gppmsc", "evapotranspirationmsc", "agb", "ndvi"],
    :set9 => ["agb", "ndvi"],
    :set10 => ["agb", "ndvi", "nirv"],
)
forcing_set = "zarr";
forcing_config = "forcing_$(forcing_set).json";
parallelization_lib = "threads"
exp_main = "wroasted_v202503_zarr"

opti_set = (:set1, :set2, :set3, :set4, :set5, :set6, :set7, :set9, :set10,)
opti_set = (:set1,)
# opti_set = (:set3,)
optimize_it = true;
o_set = :set1

# for o_set in opti_set
    path_output = "/Net/Groups/BGI/tscratch/skoirala/$(exp_main)_sjindbad/$(forcing_set)/$(o_set)"

    exp_name = "$(exp_main)_$(forcing_set)_$(o_set)"

    replace_info = Dict("experiment.basics.time.date_begin" => begin_year * "-01-01",
        "experiment.basics.config_files.forcing" => forcing_config,
        "experiment.basics.config_files.optimization" => "optimization_zarr.json",
        "experiment.basics.domain" => domain,
        "experiment.basics.name" => exp_name,
        "experiment.basics.time.date_end" => end_year * "-12-31",
        "experiment.exe_rules.input_data_backend" => "zarr",
        "experiment.flags.run_optimization" => optimize_it,
        "experiment.flags.calc_cost" => true,
        "experiment.flags.catch_model_errors" => true,
        "experiment.flags.spinup_TEM" => true,
        "experiment.flags.debug_model" => false,
        "experiment.model_spinup.sequence" => sequence,
        "forcing.default_forcing.data_path" => path_input,
        "forcing.subset.site" => [1,205],
        "experiment.model_output.path" => path_output,
        "experiment.exe_rules.parallelization" => parallelization_lib,
        "optimization.algorithm_optimization" => "opti_algorithms/CMAEvolutionStrategy_CMAES_10000.json",
        "optimization.observations.default_observation.data_path" => path_observation,
        "optimization.observational_constraints" => opti_sets[o_set],)
        info = getExperimentInfo(experiment_json; replace_info=replace_info); # note that this will modify information from json with the replace_info
        
        forcing = getForcing(info);

        observations = getObservation(info, forcing.helpers);
        run_helpers = prepTEM(forcing, info);
        @time runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
                
        @time out_opti = runExperimentOpti(experiment_json; replace_info=replace_info);

    forcing = out_opti.forcing;
    obs_array = out_opti.observation;
    info = out_opti.info;
    
    # some plots
    opt_dat = out_opti.output.optimized
    def_dat = out_opti.output.default
    costOpt = prepCostOptions(obs_array, info.optimization.cost_options)
    default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))

    # load matlab wroasted results
    nc_ml = DataLoaders.NetCDF.open(ml_data_file)

    varib_dict = Dict(:gpp => "gpp", :nee => "NEE", :transpiration => "tranAct", :evapotranspiration => "evapTotal", :ndvi => "fAPAR", :agb => "cEco", :reco => "cRECO", :nirv => "gpp")

    fig_prefix = joinpath(info.output.dirs.figure, "comparison_" * info.experiment.basics.name * "_" * info.experiment.basics.domain)

    foreach(costOpt) do var_row
        v = var_row.variable
        @show "plot obs", v
        ml_dat = nc_ml[varib_dict[v]][:]
        if v == :agb
            ml_dat = nc_ml[varib_dict[v]][1, 1, 2, :]
        elseif v == :ndvi
            ml_dat = ml_dat .- mean(ml_dat)
        end
        v = (var_row.mod_field, var_row.mod_subfield)
        vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
        v = vinfo["standard_name"]
        lossMetric = var_row.cost_metric
        loss_name = nameof(typeof(lossMetric))
        if loss_name in (:NNSEInv, :NSEInv)
            lossMetric = NSE()
        end
        valids = var_row.valids;
        (obs_var, obs_σ, def_var) = getData(def_dat, obs_array, var_row)
        (_, _, opt_var) = getData(opt_dat, obs_array, var_row)
        ml_dat[.!valids] .= NaN
        ml_var = ml_dat
        obs_var_TMP = obs_var[:, 1, 1, 1]
        non_nan_index = findall(x -> !isnan(x), obs_var_TMP)
        if length(non_nan_index) < 2
            tspan = 1:length(obs_var_TMP)
        else
            tspan = first(non_nan_index):last(non_nan_index)
        end

        obs_σ = obs_σ[tspan]
        obs_var = obs_var[tspan]
        ml_var = ml_var[tspan]
        def_var = def_var[tspan, 1, 1, 1]
        opt_var = opt_var[tspan, 1, 1, 1]
        valids = valids[tspan]

        xdata = [info.helpers.dates.range[tspan]...]

        metr_ml = metric(lossMetric, ml_var[valids], obs_var[valids], obs_σ[valids])
        metr_def = metric(lossMetric, def_var[valids], obs_var[valids], obs_σ[valids])
        metr_opt = metric(lossMetric, opt_var[valids], obs_var[valids], obs_σ[valids])

        plot(xdata, obs_var; label="obs", seriestype=:scatter, mc=:black, ms=4, lw=0, ma=0.65, left_margin=1cm)
        plot!(xdata, def_var, color=:steelblue2, lw=1.5, ls=:dash, left_margin=1cm, legend=:outerbottom, legendcolumns=4, label="def ($(round(metr_def, digits=2)))", size=(2000, 1000), title="$(vinfo["long_name"]) ($(vinfo["units"])) -> $(nameof(typeof(lossMetric))), $(forcing_set), $(o_set)")
        plot!(xdata, opt_var; color=:seagreen3, label="opt ($(round(metr_opt, digits=2)))", lw=1.5, ls=:dash)
        plot!(xdata, ml_var; label="matlab ($(round(metr_ml, digits=2)))", lw=1.5, ls=:dash)
        savefig(fig_prefix * "_$(v)_$(forcing_set).png")
    end

    # save the outcubes
    output_array_opt = values(opt_dat)
    output_array_def = values(def_dat)
    output_vars = info.output.variables
    output_dims = getOutDims(info, out_opti.forcing.helpers);

    saveOutCubes(info.output.file_info.file_prefix, info.output.file_info.global_metadata, output_array_opt, output_dims, output_vars, "zarr", info.experiment.basics.temporal_resolution, DoSaveSingleFile())
    saveOutCubes(info.output.file_info.file_prefix, info.output.file_info.global_metadata, output_array_opt, output_dims, output_vars, "zarr", info.experiment.basics.temporal_resolution, DoNotSaveSingleFile())

    saveOutCubes(info.output.file_info.file_prefix, info.output.file_info.global_metadata, output_array_opt, output_dims, output_vars, "nc", info.experiment.basics.temporal_resolution, DoSaveSingleFile())
    saveOutCubes(info.output.file_info.file_prefix, info.output.file_info.global_metadata, output_array_opt, output_dims, output_vars, "nc", info.experiment.basics.temporal_resolution, DoNotSaveSingleFile())


    # plot the debug figures
    default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
    fig_prefix = joinpath(info.output.dirs.figure, "debug_" * info.experiment.basics.name * "_" * info.experiment.basics.domain)
    for (o, v) in enumerate(output_vars)
        def_var = output_array_def[o][:, :, 1, 1]
        opt_var = output_array_opt[o][:, :, 1, 1]
        vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
        v = vinfo["standard_name"]
        println("plot debug::", v)
        xdata = [info.helpers.dates.range...]
        if size(opt_var, 2) == 1
            plot(xdata, def_var[:, 1]; label="def ($(round(SindbadTEM.mean(def_var[:, 1]), digits=2)))", size=(2000, 1000), title="$(vinfo["long_name"]) ($(vinfo["units"]))", left_margin=1cm)
            plot!(xdata, opt_var, color=:seagreen3[:, 1]; label="opt ($(round(SindbadTEM.mean(opt_var[:, 1]), digits=2)))")
            ylabel!("$(vinfo["standard_name"])", font=(20, :green))
            savefig(fig_prefix * "_$(v).png")
        else
            foreach(axes(opt_var, 2)) do ll
                plot(xdata, def_var[:, ll]; label="def ($(round(SindbadTEM.mean(def_var[:, ll]), digits=2)))", size=(2000, 1000), title="$(vinfo["long_name"]), layer $(ll),  ($(vinfo["units"]))", left_margin=1cm)
                plot!(xdata, opt_var[:, ll]; color=:seagreen3, label="opt ($(round(SindbadTEM.mean(opt_var[:, ll]), digits=2)))")
                ylabel!("$(vinfo["standard_name"])", font=(20, :green))
                savefig(fig_prefix * "_$(v)_$(ll).png")
            end
        end
    end
# end