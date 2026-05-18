using Revise
using SindbadTEM
using Sindbad
using BenchmarkTools
using Plots

toggle_type_abbrev_in_stacktrace()
experiment_json = "../exp_WROASTED/settings_WROASTED/experiment.json"
begin_year = "1999"
end_year = "2010"

domain = "CA-Obs"
path_input = nothing
forcing_config = nothing

expp = [("day", true), ("day", false), ("hour", true), ("hour", false)]
mod_step = "day"
mod_step = "hour"
# foreach(["day", "hour"]) do mod_step

# Vector to store median times
median_times = Float64[]
labels = String[]
nyears = parse(Int, end_year) - parse(Int, begin_year) + 1
nrepeat = 1
su_method = "all_forward_models"
su_method = "nlsolve_fixedpoint_trustregion_cEco"
sequence = [
        Dict("spinup_mode" => su_method, "forcing" => "first_year", "n_repeat" => nrepeat),
    ]
    

for (mod_step, do_spinup) in expp
    @show mod_step, do_spinup
    if mod_step == "day"
        path_input = "$(getSindbadDataDepot())/fn/$(domain).1979.2017.daily.nc"
        forcing_config = "forcing_erai.json"
    else
        path_input = "$(getSindbadDataDepot())/CA-Obs.1999.2010.hourly_for_Sindbad.nc"
        forcing_config = "forcing_hourly.json"
    end

    path_observation = path_input
    optimize_it = false
    path_output = nothing

    parallelization_lib = "threads"
    model_array_type = "static_array"
    replace_info = Dict("experiment.basics.time.date_begin" => begin_year * "-01-01",
        "experiment.basics.config_files.forcing" => forcing_config,
        "experiment.basics.domain" => domain,
        "experiment.basics.name" => "WROASTED_$mod_step",
        "experiment.basics.time.temporal_resolution" => mod_step,
        "forcing.default_forcing.data_path" => path_input,
        "experiment.basics.time.date_end" => end_year * "-12-31",
        "experiment.flags.run_optimization" => optimize_it,
        "experiment.flags.calc_cost" => true,
        "experiment.flags.catch_model_errors" => false,
        "experiment.flags.spinup_TEM" => do_spinup,
        "experiment.model_spinup.sequence" => sequence,
        "experiment.flags.debug_model" => false,
        "experiment.exe_rules.model_array_type" => model_array_type,
        "experiment.model_output.path" => path_output,
        "experiment.model_output.format" => "nc",
        "experiment.model_output.save_single_file" => true,
        "experiment.exe_rules.parallelization" => parallelization_lib,
        "optimization.algorithm_optimization" => "opti_algorithms/CMAEvolutionStrategy_CMAES.json",
        "optimization.observations.default_observation.data_path" => path_observation)

    info = getExperimentInfo(experiment_json; replace_info=replace_info)
    parameter_table = info.optimization.parameter_table
    forcing = getForcing(info)
    run_helpers = prepTEM(forcing, info)

    # Benchmark the runTEM! function
    bench = @benchmark runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)

    # Save the median time and label
    push!(median_times, median(bench.times))
    push!(labels, "$(mod_step)-$(do_spinup)")
end

# First Bar Chart: Median times for each experiment (simple bar chart)
bar(labels, median_times / 1e9, xlabel="Configuration", ylabel="Median Time (s)", title="($(nyears) Y, $(nrepeat) REP, S: $(begin_year), E: $(end_year))", legend=false)

# Save the first figure
savefig("benchmark_results_$(nyears)years_$(su_method)-spinup-repeat_$(nrepeat).png")

group_labels = ["day", "hour"]
# Second Bar Chart: Ratio of median times (true/false) for each mod_step
ratios = [
    median_times[i] / median_times[j]
    for (i, j) in zip(
        [k for k in 1:length(expp) if expp[k][2] == true],
        [k for k in 1:length(expp) if expp[k][2] == false]
    )
]

bar(group_labels, ratios, xlabel="Temporal Resolution", ylabel="Ratio (True/False)", title="spinup vs nospinup, $(nyears) Y, $(nrepeat) REP, S: $(begin_year), E: $(end_year)", legend=false)

group_labels = ["Spinup", "No Spinup"]
# Save the second figure
savefig("benchmark_ratios_spinup_$(nyears)years_$(su_method)-spinup-repeat_$(nrepeat).png")

# Third Bar Chart: Ratio of median times (true/false) for each mod_step
ratios = [
    median_times[i] / median_times[j]
    for (i, j) in zip(
        [k for k in 1:length(expp) if expp[k][1] == "hour"],
        [k for k in 1:length(expp) if expp[k][1] == "day"]
    )
]

bar(group_labels, ratios, xlabel="Do Spinup?", ylabel="Ratio (hour/day)", title="hour vs day, $(nyears) Y, $(nrepeat) REP, S: $(begin_year), E: $(end_year)", legend=false)

# Save the second figure
savefig("benchmark_ratios_day_hour_$(nyears)years_$(su_method)-spinup-repeat_$(nrepeat).png")
