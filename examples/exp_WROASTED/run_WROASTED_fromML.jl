using Revise
using Sindbad
using Dates
using Plots

toggle_type_abbrev_in_stacktrace()

site_index = 37
# site_index = 68
sites = 1:205
sites = [37, ]
# sites = 1:20
# sites = [11, 33, 55, 105, 148]
forcing_set = "erai"
do_debug_figs = false
do_forcing_figs = false
site_info = CSV.File(
    "/Net/Groups/BGI/work_3/sindbad/project/progno/sindbad-wroasted/sandbox/sb_wroasted/fluxnet_sites_info/site_info_$(forcing_set).csv";
    header=false);
info = nothing
forcing = nothing
models_with_matlab_params = nothing
linit = nothing
debug_span = 1:10000
if !isnothing(models_with_matlab_params)
    showParamsOfAllModels(models_with_matlab_params)
end
for site_index in sites
    # site_index = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"])
    # site_index = Base.parse(Int, ARGS[1])
    domain = string(site_info[site_index][2])

    experiment_json = "../exp_WROASTED/settings_WROASTED/experiment.json"
    begin_year = nothing
    end_year = nothing
    ml_main_dir = nothing
    if forcing_set == "erai"
        dataset = "ERAinterim.v2"
        begin_year = "1979"
        end_year = "2017"
        ml_main_dir = "/Net/Groups/BGI/scratch/skoirala/sopt_sets_wroasted/"
    else
        dataset = "CRUJRA.v2_2"
        begin_year = "1901"
        end_year = "2019"
        ml_main_dir = "/Net/Groups/BGI/scratch/skoirala/cruj_sets_wroasted/"
    end
    ml_parameter_file = joinpath(ml_main_dir, "sindbad_raw_set1/fluxnetBGI2021.BRK15.DD", dataset, domain, "optimization", "optimized_Params_FLUXNET_pcmaes_FLUXNET2015_daily_$(domain).json")
    ml_data_file = joinpath(ml_main_dir, "sindbad_processed_sets/set1/fluxnetBGI2021.BRK15.DD", dataset, "data", "$(domain).$(begin_year).$(end_year).daily.nc")

    ml_data_path = joinpath(ml_main_dir, "sindbad_raw_set1/fluxnetBGI2021.BRK15.DD", dataset, domain, "modelOutput")
    if do_debug_figs
        ml_data_path = joinpath(ml_main_dir, "sindbad_raw_set1PF/fluxnetBGI2021.BRK15.DD", dataset, domain, "modelOutput")
    end

    path_input = joinpath("/Net/Groups/BGI/scratch/skoirala/wroasted/fluxNet_0.04_CLIFF/fluxnetBGI2021.BRK15.DD/data", dataset, "daily/$(domain).$(begin_year).$(end_year).daily.nc")

    path_observation = path_input
    forcing_config = "forcing_$(forcing_set).json"

    path_output = "/Net/Groups/BGI/tscratch/skoirala/sjindbad_from_ml_params"



    ## get the spinup sequence

    nrepeat = 200

    # data_path = getAbsDataPath(info, path_input)
    data_path = path_input
    if !isfile(data_path)
        continue
    end
    nc = DataLoaders.NetCDF.open(data_path)
    y_dist = nc.gatts["last_disturbance_on"]

    nrepeat_d = nothing
    if y_dist !== "undisturbed"
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

    parallelization_lib = "threads"
    replace_info = Dict("experiment.basics.time.date_begin" => begin_year * "-01-01",
        "experiment.basics.config_files.optimization" => "optimization_1_1.json",
        "experiment.basics.config_files.forcing" => forcing_config,
        "experiment.basics.domain" => domain,
        "forcing.default_forcing.data_path" => path_input,
        "experiment.basics.time.date_end" => end_year * "-12-31",
        "experiment.flags.run_optimization" => false,
        "experiment.flags.calc_cost" => true,
        "experiment.flags.catch_model_errors" => false,
        "experiment.flags.spinup_TEM" => true,
        "experiment.flags.debug_model" => false,
        "experiment.model_spinup.sequence" => sequence[2:end],
        "experiment.model_output.path" => path_output,
        "experiment.exe_rules.parallelization" => parallelization_lib,
        "optimization.algorithm_optimization" => "opti_algorithms/CMAEvolutionStrategy_CMAES.json",
        "optimization.observations.default_observation.data_path" => path_observation,)


    info = getExperimentInfo(experiment_json; replace_info=replace_info) # note that this will modify information from json with the replace_info

    forcing = getForcing(info)

    ### update the model parameters with values from matlab optimization
parameter_table = info.optimization.parameter_table;
    opt_params = parameter_table.optimized
    parameter_names = parameter_table.name_full
    parameter_maps = Sindbad.parsefile("examples/exp_WROASTED/settings_WROASTED/ml_to_jl_params.json"; dicttype=Sindbad.DataStructures.OrderedDict)

    if isfile(ml_parameter_file)
        ml_params = Sindbad.parsefile(ml_parameter_file; dicttype=Sindbad.DataStructures.OrderedDict)["parameter"]

        for opi in eachindex(opt_params)
            jl_name = parameter_names[opi]
            ml_name = parameter_maps[jl_name]
            println(jl_name, "=>", ml_name)
            ml_model = split(ml_name, ".")[1]
            ml_p = split(ml_name, ".")[2]
            ml_value = ml_params[ml_model][ml_p]
            @show opt_params[opi], "old"
            opt_params[opi] = oftype(opt_params[opi], ml_value)
            @show opt_params[opi], "new"
            @info "\n------------------------------------------------\n"
        end
        models_with_matlab_params = updateModelParameters(parameter_table, info.models.forward, opt_params)


        parameter_table_2 = info.optimization.parameter_table;

        ## run the model

        run_helpers = prepTEM(models_with_matlab_params, forcing, info)
        @time runTEM!(models_with_matlab_params,
            run_helpers.space_forcing,
            run_helpers.space_spinup_forcing,
            run_helpers.loc_forcing_t,
            run_helpers.output_array,
            run_helpers.space_land,
            run_helpers.tem_info)

        outcubes = run_helpers.output_array

        observations = getObservation(info, forcing.helpers)
        obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because view of keyedarray is slow.

        varib_dict = Dict(:gpp => "gpp", :nee => "NEE", :transpiration => "tranAct", :evapotranspiration => "evapTotal", :ndvi => "fAPAR", :agb => "cEco", :reco => "cRECO", :soilW => "wSoil", :gpp_f_soilW => "SMScGPP", :gpp_f_vpd => "VPDScGPP", :gpp_climate_stressors => "scall", :WUE => "WUE", :eco_respiration => "cRECO", :c_allocation => "cAlloc", :fAPAR => "fAPAR", :cEco => "cEco", :PAW => "pawAct", :transpiration_supply => "tranSup", :c_eco_k => "p_cTauAct_k", :auto_respiration => "cRA", :hetero_respiration => "cRH", :runoff => "roTotal", :base_runoff => "roBase", :gw_recharge => "gwRec", :c_eco_k_f_soilT => "fT", :c_eco_k_f_soilW => "p_cTaufwSoil_fwSoil", :snow_melt => "snowMelt", :groundW => "wGW", :snowW => "wSnow", :frac_snow => "wSnowFrac", :c_eco_influx => "cEcoInflux", :c_eco_efflux => "cEcoEfflux", :c_eco_out => "cEcoOut", :c_eco_flow => "cEcoFlow", :leaf_to_reserve_frac => "L2ReF", :root_to_reserve_frac => "R2ReF", :reserve_to_leaf_frac => "Re2L", :reserve_to_root_frac => "Re2R", :k_shedding_leaf_frac => "k_LshedF", :k_shedding_root_frac => "k_RshedF", :root_water_efficiency => "p_rootFrac_fracRoot2SoilD")

        # some plots for model simulations from JL and matlab versions
        opt_dat = outcubes
        output_vars = val_to_symbol(run_helpers.tem_info.vals.output_vars)
        costOpt = prepCostOptions(obs_array, info.optimization.cost_options)
        default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
        foreach(costOpt) do var_row
            v = var_row.variable
            @show "plot obs", v
            println("plot obs-model => site: $domain, variable: $v")
            lossMetric = var_row.cost_metric
            loss_name = nameof(typeof(lossMetric))
            if loss_name in (:NNSEInv, :NSEInv)
                lossMetric = NSE()
            end
            ml_data_file = joinpath(ml_data_path, "FLUXNET2015_daily_$(domain)_FLUXNET_$(varib_dict[v]).nc")
            @show ml_data_file
            nc_ml = DataLoaders.NetCDF.open(ml_data_file)
            ml_dat = nc_ml[varib_dict[v]][:]
            if v == :agb
                ml_dat = nc_ml[varib_dict[v]][1, 2, :]
            elseif v == :ndvi
                ml_dat = ml_dat .- mean(ml_dat)
            end
            valids = var_row.valids;
            ml_dat[.!valids] .= NaN
            ml_var = ml_dat
            (obs_var, obs_σ, jl_dat) = getData(opt_dat, obs_array, var_row)

            obs_var_TMP = obs_var[:, 1, 1, 1]
            non_nan_index = findall(x -> !isnan(x), obs_var_TMP)
            tspan = 1:length(obs_var_TMP)
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
            metr_def = metric(lossMetric, ml_dat[valids], obs_var[valids], obs_σ[valids])
            metr_opt = metric(lossMetric, jl_dat[valids], obs_var[valids], obs_σ[valids])
            v = (var_row.mod_field, var_row.mod_subfield)
            vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
            v = vinfo["standard_name"]
            plot(xdata, obs_var; label="obs", seriestype=:scatter, mc=:black, ms=4, lw=0, ma=0.65, left_margin=1cm)
            plot!(xdata, ml_dat, lw=1.5, ls=:dash, left_margin=1cm, legend=:outerbottom, legendcolumns=3, label="matlab ($(round(metr_def, digits=2)))", size=(2000, 1000), title="$(vinfo["long_name"]) ($(vinfo["units"])) -> $(nameof(typeof(lossMetric)))")
            plot!(xdata, jl_dat; label="julia ($(round(metr_opt, digits=2)))", lw=1.5, ls=:dash)
            savefig("examples/exp_WROASTED/tmp_figs_comparison/wroasted_$(domain)_$(v)_$(forcing_set).png")
            # savefig(fig_prefix * "_$(v)_$(forcing_set).png")
        end

        if do_debug_figs
            ##plot more diagnostic figures for sindbad jl

            replace_info["experiment.flags.run_optimization"] = false
            replace_info["experiment.flags.calc_cost"] = false
            info = getExperimentInfo(experiment_json; replace_info=replace_info)
            # note that this will modify information from json with the replace_info
            forcing = getForcing(info)

            run_helpers = prepTEM(models_with_matlab_params,
                    forcing,
                    info)                                
            runTEM!(models_with_matlab_params,
                run_helpers.space_forcing,
                run_helpers.space_spinup_forcing,
                run_helpers.loc_forcing_t,
                run_helpers.space_output,
                run_helpers.space_land,
                run_helpers.tem_info)

            default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
            output_vars = val_to_symbol(run_helpers.tem_info.vals.output_vars)
            for (o, v) in enumerate(output_vars)
                println("plot dbg-model => site: $domain, variable: $v")
                def_var = run_helpers.output_array[o][:, :, 1, 1]
                xdata = [info.helpers.dates.range...][debug_span]
                vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
                ml_dat = nothing
                if v in keys(varib_dict)
                    ml_data_file = joinpath(ml_data_path, "FLUXNET2015_daily_$(domain)_FLUXNET_$(varib_dict[v]).nc")
                    @show ml_data_file
                    nc_ml = DataLoaders.NetCDF.open(ml_data_file)
                    ml_dat = nc_ml[varib_dict[v]]
                end
                if size(def_var, 2) == 1
                    plot(xdata, def_var[debug_span, 1]; label="julia ($(round(SindbadTEM.mean(def_var[debug_span, 1]), digits=2)))", size=(2000, 1000), title="$(vinfo["long_name"]) ($(vinfo["units"]))", left_margin=1cm)
                    if !isnothing(ml_dat)
                        plot!(xdata, ml_dat[debug_span]; label="matlab ($(round(SindbadTEM.mean(ml_dat[debug_span]), digits=2)))", size=(2000, 1000))
                    end
                    savefig(joinpath("examples/exp_WROASTED/tmp_figs_comparison/", "dbg_wroasted_$(domain)_$(vinfo["standard_name"])_$(forcing_set).png"))
                else
                    foreach(axes(def_var, 2)) do ll
                        plot(xdata, def_var[debug_span, ll]; label="julia ($(round(SindbadTEM.mean(def_var[debug_span, ll]), digits=2)))", size=(2000, 1000), title="$(vinfo["long_name"]), layer $ll ($(vinfo["units"]))", left_margin=1cm)
                        println("           layer => $ll")

                        if !isnothing(ml_dat)
                            plot!(xdata, ml_dat[1, ll, debug_span]; label="matlab ($(round(SindbadTEM.mean(ml_dat[1, ll, debug_span]), digits=2)))")
                        end
                        savefig(joinpath("examples/exp_WROASTED/tmp_figs_comparison/", "dbg_wroasted_$(domain)_$(vinfo["standard_name"])_$(ll)_$(forcing_set).png"))
                    end
                end
            end
        end

        if do_forcing_figs
            ### PLOT the forcings
            default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
            forc_vars = forcing.variables
            for (o, v) in enumerate(forc_vars)
                println("plot forc-model => site: $domain, variable: $v")
                def_var = forcing.data[o][:, :, 1, 1]
                xdata = [info.helpers.dates.range...]
                if size(def_var, 1) !== length(xdata)
                    xdata = 1:size(def_var, 1)
                end
                if size(def_var, 2) == 1
                    plot(xdata, def_var[:, 1]; label="def ($(round(SindbadTEM.mean(def_var[:, 1]), digits=2)))", size=(2000, 1000), title="$(v)")
                    savefig(joinpath("examples/exp_WROASTED/tmp_figs_comparison/", "forc_wroasted_$(domain)_$(v)_$(forcing_set).png"))
                else
                    foreach(axes(def_var, 2)) do ll
                        plot(xdata, def_var[:, ll]; label="def ($(round(SindbadTEM.mean(def_var[:, ll]), digits=2)))", size=(2000, 1000), title="$(v)")
                        savefig(joinpath("examples/exp_WROASTED/tmp_figs_comparison/", "forc_wroasted_$(domain)_$(v)_$(ll)_$(forcing_set).png"))
                    end
                end

            end

        end
    end
end