using Revise
using Sindbad
using Sindbad.DataLoaders
using Plots
using Plots: cm

using NLsolve
# using Accessors
toggle_type_abbrev_in_stacktrace()
default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
function plot_and_save(land, out_sp_exp, out_sp_exp_nl, out_sp_nl, xtname, plot_elem, plot_var, tj, model_array_type, out_path)
    plot_elem = string(plot_elem)
    if plot_var == :cEco
        plt = plot(; legend=:outerbottom, legendcolumns=4, size=(1800, 1200), yscale=:log10, left_margin=1cm, title="$(plot_var), jump: $tj")
        ylims!(0.00000001, 1e9)
    else
        plt = plot(; legend=:outerbottom, legendcolumns=4, size=(1800, 1200), left_margin=1cm,  title="$(plot_var), jump: $tj")
        ylims!(10, 2000)
    end
    plot!(getfield(land.pools, plot_var);
        linewidth=5,
        xaxis="Pool",
        label="Init\n($(round(SindbadTEM.mean(getfield(land.pools, plot_var)), digits=2)))")

    plot!(getfield(out_sp_exp.pools, plot_var);
        linewidth=5,
        label="Exp_Init\n($(round(SindbadTEM.mean(getfield(out_sp_exp.pools, plot_var)), digits=2)))")
    # title="SU: $(plot_elem) - $(plot_var):: jump => $(tj), $(model_array_type)")
    plot!(getfield(out_sp_exp_nl.pools, plot_var);
        linewidth=5,
        ls=:dash,
        label="Exp_NL\n($(round(SindbadTEM.mean(getfield(out_sp_exp_nl.pools, plot_var)), digits=2)))")
    plot!(getfield(out_sp_nl.pools, plot_var);
        linewidth=5,
        ls=:dot,
        label="NL_Solve\n($(round(SindbadTEM.mean(getfield(out_sp_nl.pools, plot_var)), digits=2)))",
        xticks=(1:length(xtname) |> collect, string.(xtname)),
        rotation=45)

    savefig(joinpath(out_path, "$(string(plot_var))_sin_explicit_$(plot_elem)_$(model_array_type)_tj-$(tj).png"))
    return nothing
end

function get_xtick_names(info, land_for_s, look_at)
    xtname = []
    xtl = nothing
    if look_at == :cEco
        xtl = land_for_s.diagnostics.c_eco_τ
    end
    for (i, comp) ∈ enumerate(getfield(info.helpers.pools.components, look_at))
        zix = getfield(info.helpers.pools.zix, comp)
        for iz in eachindex(zix)
            if look_at == :cEco
                push!(xtname, string(comp) * "\n" * string(xtl[i]))
            else
                push!(xtname, string(comp) * "_$(iz)")
            end
        end
    end
    return xtname
end
experiment_json = "../exp_steadyState/settings_steadyState/experiment.json"
out_sp_exp = nothing
model_array_type = "static_array"
tjs = (1,)# 100, 1_000, 10_000)
# tjs = (1000,)
# tjs = (10_000,)
nLoop_pre_spin = 10
# for model_array_type ∈ ("static_array",)
# for model_array_type ∈ ("array",) #, "static_array")
set_log_level(:warn)
model_array_type = "static_array"
for model_array_type ∈ ("static_array",) #, "array") #, "static_array")
    replace_info = Dict("experiment.exe_rules.model_array_type" => model_array_type,
        "experiment.flags.debug_model" => false);
    println("model_array_type: ", model_array_type)

    info = getConfiguration(experiment_json; replace_info=replace_info);
    info = setupInfo(info);
    forcing = getForcing(info);

    run_helpers = prepTEM(forcing, info);

    space_forcing = run_helpers.space_forcing;
    loc_forcing_t = run_helpers.loc_forcing_t;
    output_array = run_helpers.output_array;
    space_output = run_helpers.space_output;
    space_land = run_helpers.space_land;
    tem_info = run_helpers.tem_info;
    spinup_forcing = run_helpers.space_spinup_forcing[1]


    spinupforc = :day_MSC
    theforcing = getfield(spinup_forcing, spinupforc)

    n_timesteps = getfield(run_helpers.tem_info.spinup_sequence[findfirst(x -> x.forcing === spinupforc, run_helpers.tem_info.spinup_sequence)], :n_timesteps)

    spinup_models = info.models.forward[info.models.is_spinup]
    out_path = info.output.dirs.figure
    sel_pool = :cEco_TWS
    for sel_pool in (:cEco_TWS,)
    # for sel_pool in (:cEco,)
    # for sel_pool in (:TWS,)
    # for sel_pool in (:cEco,)
    # for sel_pool in (:TWS, :cEco, :cEco_TWS)

        look_at = sel_pool

        if sel_pool in (:cEco_TWS,)
            look_at = :cEco
        end
        land_for_s = deepcopy(run_helpers.loc_land)

        xtname_c = get_xtick_names(info, land_for_s, :cEco)
        xtname_w = get_xtick_names(info, land_for_s, :TWS)
        println("pre-run: ", sel_pool)
        @time for nl ∈ 1:nLoop_pre_spin
            land_for_s = Sindbad.Simulation.spinup(spinup_models, theforcing, loc_forcing_t, land_for_s, tem_info, n_timesteps, SelSpinupModels())
        end
        println("..............................")

        # sel_pool = :TWS
        sp_method = getfield(Types, to_uppercase_first("nlsolve_fixedpoint_trustregion_$(string(sel_pool))"))()
        println("NL_solve: ")
        @time out_sp_nl = Sindbad.Simulation.spinup(spinup_models, theforcing, loc_forcing_t, deepcopy(land_for_s), tem_info, n_timesteps, sp_method)
        println("..............................")

        for tj ∈ tjs
            land = deepcopy(run_helpers.loc_land)
            println("Exp_Init: ", tj)
            sp = SelSpinupModels()
            out_sp_exp = deepcopy(land_for_s)
            @time for nl ∈ 1:tj
                out_sp_exp = Sindbad.Simulation.spinup(spinup_models, theforcing, loc_forcing_t, out_sp_exp, tem_info, n_timesteps, sp)
            end
            println("..............................")
            println("Exp_NL: ", tj)
            out_sp_exp_nl = deepcopy(out_sp_nl)
            @time for nl ∈ 1:tj
                out_sp_exp_nl = Sindbad.Simulation.spinup(spinup_models, theforcing, loc_forcing_t, out_sp_exp_nl, tem_info, n_timesteps, sp)
            end
            println("..............................")
            if sel_pool in (:cEco_TWS,)
                plot_and_save(land, out_sp_exp, out_sp_exp_nl, out_sp_nl, xtname_c, sel_pool, :cEco, tj, model_array_type, out_path)
                plot_and_save(land, out_sp_exp, out_sp_exp_nl, out_sp_nl, xtname_w, sel_pool, :TWS, tj, model_array_type, out_path)
            elseif sel_pool == :cEco
                plot_and_save(land, out_sp_exp, out_sp_exp_nl, out_sp_nl, xtname_c, :C, :cEco, tj, model_array_type, out_path)
            else
                plot_and_save(land, out_sp_exp, out_sp_exp_nl, out_sp_nl, xtname_w, :W, :TWS, tj, model_array_type, out_path)
            end
        end
        println("--------------------------------------------")
    end
    println("###########################################################################################")
end