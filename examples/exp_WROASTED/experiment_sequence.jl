using Revise
using Sindbad
using Dates
using Plots

using NetCDF
toggle_type_abbrev_in_stacktrace()
experiment_json = "../exp_WROASTED/settings_WROASTED/experiment.json"
begin_year = "1979"
end_year = "2017"

sites = ("FI-Sod", "DE-Hai", "CA-TP1", "AU-DaP", "AT-Neu")
# sites = ("AU-DaP", "AT-Neu")
# sites = ("CA-NS6",)
domain = "FI-Sod"
for domain ∈ sites
    path_input = "$(getSindbadDataDepot())/fn/$(domain).1979.2017.daily.nc"
    forcing_config = "forcing_erai.json"

    path_observation = path_input
    optimize_it = false
    optimize_it = true
    path_output = nothing


    parallelization_lib = "threads"
    replace_info = Dict("experiment.basics.time.date_begin" => begin_year * "-01-01",
        "experiment.basics.config_files.forcing" => forcing_config,
        "experiment.basics.domain" => domain,
        "experiment.basics.time.date_end" => end_year * "-12-31",
        "experiment.flags.run_optimization" => optimize_it,
        "experiment.flags.calc_cost" => true,
        "experiment.flags.catch_model_errors" => true,
        "experiment.flags.spinup_TEM" => true,
        "experiment.flags.debug_model" => false,
        "forcing.default_forcing.data_path" => path_input,
        "experiment.model_output.path" => path_output,
        "experiment.exe_rules.parallelization" => parallelization_lib,
        "optimization.observations.default_observation.data_path" => path_observation)

    ## get the spinup sequence
    nrepeat = 200
    data_path = joinpath("./examples/exp_WROASTED",path_input)
    # data_path = getAbsDataPath(info, path_input)
    nc = NetCDF.open(data_path)
    y_dist = nc.gatts["last_disturbance_on"]

    nrepeat_d = -1
    if y_dist !== "undisturbed"
        y_disturb = year(Date(y_dist))
        y_start = Meta.parse(begin_year)
        # y_start = year(Date(info.helpers.dates.date_begin))
        nrepeat_d = y_start - y_disturb
    end
    sequence = nothing
    sequence = [
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat),
        Dict("spinup_mode" => "eta_scale_AH", "forcing" => "day_MSC", "n_repeat" => 1),
    ]
    if nrepeat_d == 0
        sequence = [
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat),
            Dict("spinup_mode" => "eta_scale_A0H", "forcing" => "day_MSC", "n_repeat" => 1),
        ]
    elseif nrepeat_d > 0
        sequence = [
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat),
            Dict("spinup_mode" => "eta_scale_A0H", "forcing" => "day_MSC", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat_d),
        ]
    end

    replace_info["experiment.model_spinup.sequence"] = sequence
    @time out_opti = runExperimentOpti(experiment_json; replace_info=replace_info)

    info = out_opti.info;
    observation = out_opti.observation;

    # some plots
    plotTimeSeries(out_opti)

    optimized_data = out_opti.output.optimized
    default_data = out_opti.output.default

    # debug plots for the same optimized/default data (see below) - flagging a behavior
    # change vs. the original inline code: plotTimeSeries's shared helper reduces the
    # pixel dimension via `mean(...; dims=3)`, whereas this script previously indexed a
    # single site directly (`[:, :, 1, 1]`); for a single-site run these are equivalent.
    plotTimeSeries(info, optimized_data, default_data)

    # save the outcubes

    optimized_data = values(optimized_data)
    default_data = values(default_data)

    output_vars = info.output.variables
    output_dims = getOutDims(info, out_opti.forcing.helpers);
    saveOutCubes(info.output.file_info.file_prefix, info.output.file_info.global_metadata, optimized_data, output_dims, output_vars, "zarr", info.experiment.basics.temporal_resolution, DoSaveSingleFile())
    saveOutCubes(info.output.file_info.file_prefix, info.output.file_info.global_metadata, optimized_data, output_dims, output_vars, "zarr", info.experiment.basics.temporal_resolution, DoNotSaveSingleFile())

    saveOutCubes(info.output.file_info.file_prefix, info.output.file_info.global_metadata, optimized_data, output_dims, output_vars, "nc", info.experiment.basics.temporal_resolution, DoSaveSingleFile())
    saveOutCubes(info.output.file_info.file_prefix, info.output.file_info.global_metadata, optimized_data, output_dims, output_vars, "nc", info.experiment.basics.temporal_resolution, DoNotSaveSingleFile())

end