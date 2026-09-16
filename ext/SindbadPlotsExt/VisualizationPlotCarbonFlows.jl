# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.Visualization: plotCarbonFlows

"""
    _CARBON_FLOW_COLORS

Colors cycled per giver pool, so flows sharing a source share a color.
"""
const _CARBON_FLOW_COLORS = ["#1f77b4", "#d62728", "#2ca02c", "#9467bd", "#ff7f0e",
    "#17becf", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22"]

"""
    _INDEX_FONT

Bold font for flow labels. A family name, not Plots' `:bold` (GR has no `bold.ttf` and
would silently fall back); `"Helvetica Bold"` is a built-in GR face.
"""
const _INDEX_FONT = "Helvetica Bold"

"""
    _indexTextColor(hex_color)

Return `:white` or `:black`, whichever is legible on a cell filled with `hex_color`.
"""
function _indexTextColor(hex_color)
    red = parse(Int, hex_color[2:3]; base=16)
    green = parse(Int, hex_color[4:5]; base=16)
    blue = parse(Int, hex_color[6:7]; base=16)
    return 0.299red + 0.587green + 0.114blue < 160 ? :white : :black
end

"""
    _carbonPoolNames(approach)

Return `(pool_names, configuration_name)`: `approach`'s leaf pool names in `cEco`
index order, and the configuration they came from.
"""
function _carbonPoolNames(approach)
    approach_name = nameof(approach isa Type ? approach : typeof(approach))
    configuration = poolConfiguration(approach)
    if isnothing(configuration)
        error("$(approach_name) declares no poolConfiguration, so it has no pool " *
              "structure to draw. Pass a cCycleBase approach that declares one.")
    end
    structure = poolStructure(configuration)
    if isnothing(structure)
        error("$(approach_name) resolves to the configuration $(nameof(configuration)), " *
              "which declares no poolStructure.")
    end
    components = getfield(structure, :components)
    _, _, _, _, sub_pool_name, _ = getPoolInformation(Symbol.(keys(components)), components,
        Float64[], Int64[], Int64[], [], Symbol[], Symbol[])
    return Tuple(unique(sub_pool_name)), nameof(configuration)
end

"""
    _poolNamePrefixes(pool_names)

Return every camelCase-hump prefix of every name (e.g. `cLitRootFineFast` yields
`cLit`, `cLitRoot`, `cLitRootFine`, `cLitRootFineFast`), deduplicated. These are the
group names approaches key `zix` lookups by (`zix.cVeg`, `zix.cLitRootFine`, ...), so
this builds a generic `zix` without hand-listing groups per approach.
"""
function _poolNamePrefixes(pool_names)
    prefixes = String[]
    for name in String.(pool_names)
        tokens = [m.match for m in eachmatch(r"[A-Z][a-z0-9]*|^[a-z]+", name)]
        cum = tokens[1]
        for token in tokens[2:end]
            cum *= token
            push!(prefixes, cum)
        end
        push!(prefixes, name)
    end
    return unique(prefixes)
end

"""
    _syntheticCarbonLand(approach, pool_names, veg_type_name, extra_approaches)

Build a minimal `land`/`helpers`, run `define`+`precompute` for a fresh,
default-parameterized instance of `approach`'s own type (even if `approach` was given
as an instance, e.g. a real, already fitted-and-unit-converted one from
`info.models.forward`) and then `extra_approaches` on it, and return `(land,
helpers)` -- or `(nothing, nothing)` if that raises for this approach (caller falls
back to an index-only label).

No forcing, spatial data or real experiment involved: `zix` comes from `pool_names`
(`_poolNamePrefixes`), and `land` carries only the placeholder fields `define`/
`precompute` read (`states.veg_type_name`, `vegClass.veg_type_class_map`, zeroed
`pools.cEco`).
"""
function _syntheticCarbonLand(approach, pool_names, veg_type_name, extra_approaches)
    try
        n_pools = length(pool_names)
        # cVeg/cLit/cMic/cSoil must exist even where empty (e.g. GSI has no microbial pool)
        zix_names = Symbol.(union(_poolNamePrefixes(pool_names), ("cVeg", "cLit", "cMic", "cSoil")))
        zix = NamedTuple{Tuple(zix_names)}(Tuple(
            Tuple(findall(nm -> startswith(String(nm), String(prefix)), pool_names))
            for prefix ∈ zix_names))
        helpers = (; pools=(; zix=zix, components=(; cEco=pool_names),
            zeros=(; cEco=zeros(n_pools)), ones=(; cEco=ones(n_pools))))
        land = (; pools=(; cEco=zeros(n_pools)), diagnostics=(;), cCycleBase=(;), models=(;),
            states=(; veg_type_name=veg_type_name),
            vegClass=(; veg_type_class_map=Classification_SINDBAD()))

        # always a fresh, canonical instance, in the approach's own declared ("year")
        # units -- an instance passed in (e.g. from info.models.forward) may have its
        # rate scalars already unit-converted for a specific experiment's model_timestep,
        # which would silently throw off T's implicit year units below
        approach_instance = (approach isa Type ? approach : typeof(approach))()
        land = define(approach_instance, nothing, land, helpers)
        land = precompute(approach_instance, nothing, land, helpers)
        for extra_approach ∈ extra_approaches
            land = define(extra_approach, nothing, land, helpers)
            land = precompute(extra_approach, nothing, land, helpers)
        end
        return land, helpers
    catch e
        print_info(plotCarbonFlows, @__FILE__, @__LINE__,
            "could not derive real T/A/M/Q values for $(nameof(approach isa Type ? approach : typeof(approach))): " *
            "$(sprint(showerror, e)). Falling back to index-only flow labels.", n_f=4)
        return nothing, nothing
    end
end

"""
    _flowDetailLabel(flow, giver, k_base, a_vec, me_vec, qp_vec)

Flow-cell label text: one line each for whichever of `k_base` (`T:`, giver's turnover
time, `1/k_base[giver]` years), `a_vec` (`A:`, the flow's allocation fraction),
`me_vec` (`M:`, microbial efficiency) and `qp_vec` (`Q:`, quality-partition fraction)
is not `nothing`; `""` if none are available. The flow's index is drawn separately,
at the start of its arrow (see `plotCarbonFlows`), so the cell is free to give these
lines more room.
`k_base[giver] == 0` shows `T:-` rather than dividing by zero.
"""
function _flowDetailLabel(flow, giver, k_base, a_vec, me_vec, qp_vec)
    lines = String[]
    if !isnothing(k_base)
        k = k_base[giver]
        push!(lines, k > 0 ? "T:$(round(1 / k, digits=1))y" : "T:-")
    end
    isnothing(a_vec) || push!(lines, "A:$(round(a_vec[flow], digits=2))")
    isnothing(me_vec) || push!(lines, "M:$(round(me_vec[flow], digits=2))")
    isnothing(qp_vec) || push!(lines, "Q:$(round(qp_vec[flow], digits=2))")
    return join(lines, "\n")
end

"""
    _flowFanOffsets(keys_of_flows)

Return one small offset per flow, spreading flows that share a key evenly about zero
(so arrows sharing a giver/taker don't overlap).
"""
function _flowFanOffsets(keys_of_flows)
    # fixed band width regardless of group size, so a large group still separates clearly
    spread = 0.62
    offsets = zeros(length(keys_of_flows))
    for key ∈ unique(keys_of_flows)
        members = findall(==(key), keys_of_flows)
        n_members = length(members)
        n_members == 1 && continue
        for (rank, flow) ∈ enumerate(members)
            offsets[flow] = spread * (rank - (n_members + 1) / 2) / (n_members - 1)
        end
    end
    return offsets
end

"""
    plotCarbonFlows(approach; kwargs...)
    plotCarbonFlows(approach, file_path; kwargs...)

Draw a `cCycleBase` approach's carbon flow topology as a giver-by-taker matrix, one
labelled arrow per flow.

# Arguments
- `approach`: a `cCycleBase` approach, type or instance (e.g. `cCycleBase_CASA`), or
  `nothing` to derive it from `land.models.c_model` (every cCycleBase approach packs
  its own instance there in `define`) -- only valid together with `land`. Without
  `land`, only its type matters: the synthetic path always builds a fresh, default-
  parameterized instance, ignoring a given instance's own field values (which, e.g.
  from `info.models.forward`, may carry a specific experiment's fitted and
  unit-converted parameters).
- `file_path`: output path, or `nothing` to skip saving.

# Keyword arguments
- `land`: a `define`+`precompute`d land from a real experiment run. When given,
  topology and T/A/M/Q come from it instead of a synthetic run, reflecting that
  experiment's actual pool structure and selected approaches -- `land` alone is
  enough; `helpers` is never read for this.
- `helpers`: optional even with `land` given; the only use is reading
  `helpers.dates.temporal_resolution` to convert T to years (see `model_timestep`
  below), so pass it only for that, or skip it and pass `model_timestep` directly.
- `veg_type_name`: vegetation type for the synthetic path's turnover-time tables,
  default `land.states.veg_type_name` when `land` is given (else
  `:Evergreen_Needleleaf_Forests`). Unused when `land` is given (its own real
  `states.veg_type_name` is what actually produced its diagnostics).
- `extra_approaches`: instances (e.g. `cQualityPartition_equal()`,
  `cMicrobialEfficiency_constant()`) whose `define`+`precompute` run after
  `approach`'s own, to populate M/Q beyond its built-in defaults. Ignored when
  `land` is given.
- `model_timestep`: overrides the experiment's temporal resolution, read by default
  from `helpers.dates.temporal_resolution` if `helpers` is given (falling back to
  `"day"` otherwise). `land`'s `c_eco_k_base` is in this unit, not years -- its rate
  parameters go through automatic timescale conversion before a real run, unlike the
  synthetic path's unconverted defaults -- so T is rescaled by it to read in years.
  Ignored when `land` is not given.

# Returns
- `nothing` when saved to `file_path`; the plot object, unsaved and undisplayed, when
  `file_path` is `nothing`.

# Description
- Pools sit on the diagonal in `cEco` index order, named on all four sides. x is the
  giver, y is the taker.
- Each flow is an elbow from the giver's box to the taker's box. Its index is drawn
  where the arrow leaves the giver's box; the cell it turns in is labelled, where
  available, with T (giver turnover time, years), A (the flow's allocation fraction),
  M (microbial efficiency), and Q (quality-partition fraction).

# Notes
- With no `land`, this needs no experiment, forcing or spatial data: a synthetic
  `define`+`precompute` run supplies T/A/M/Q (see `_syntheticCarbonLand`); if that
  fails for `approach`, labels fall back to the bare index.
"""
function plotCarbonFlows(approach, file_path, ::VisualizationPlots;
        land=nothing, helpers=nothing,
        veg_type_name::Symbol=isnothing(land) ? :Evergreen_Needleleaf_Forests : land.states.veg_type_name,
        extra_approaches=(), model_timestep::Union{String,Nothing}=nothing)
    if isnothing(approach)
        isnothing(land) && error("plotCarbonFlows needs `approach`, or `land` to derive " *
            "it from `land.models.c_model`.")
        approach = land.models.c_model
    end
    approach_name = nameof(approach isa Type ? approach : typeof(approach))
    pool_names, configuration_name = _carbonPoolNames(approach)
    flow_matrix = cFlowMatrix(approach, pool_names)
    n_pools = length(pool_names)

    print_info(plotCarbonFlows, @__FILE__, @__LINE__, "plotting carbon flows of $(approach_name) over $(n_pools) pools", n_f=6)

    # flow k's giver/taker, in flow order
    n_flows = maximum(flow_matrix)
    givers = zeros(Int, n_flows)
    takers = zeros(Int, n_flows)
    for taker ∈ 1:n_pools, giver ∈ 1:n_pools
        flow = flow_matrix[taker, giver]
        flow == 0 && continue
        givers[flow] = giver
        takers[flow] = taker
    end

    # a caller-supplied land wins on topology too (may differ from approach's own
    # poolConfiguration); synthetic path keeps the topology derived above and only adds
    # land.diagnostics values on top. helpers is never read for topology/diagnostics --
    # only, optionally, for helpers.dates.temporal_resolution below.
    using_real_land = !isnothing(land)
    if using_real_land
        # cFlowStructure's pool_names is `i => name` pairs, not bare names
        pool_names = last.(land.cCycleBase.pool_names)
        givers = collect(land.cCycleBase.c_giver)
        takers = collect(land.cCycleBase.c_taker)
        n_pools = length(pool_names)
        n_flows = length(land.cCycleBase.c_flow_order)
    else
        land, helpers = _syntheticCarbonLand(approach, pool_names, veg_type_name, extra_approaches)
    end
    k_base = isnothing(land) ? nothing : get(land.diagnostics, :c_eco_k_base, nothing)
    a_vec = isnothing(land) ? nothing : get(land.diagnostics, :c_flow_A_vec, nothing)
    me_vec = isnothing(land) ? nothing : get(land.diagnostics, :c_flow_ME_vec, nothing)
    qp_vec = isnothing(land) ? nothing : get(land.diagnostics, :c_flow_QP_vec, nothing)
    has_details = !isnothing(k_base) || !isnothing(a_vec) || !isnothing(me_vec) || !isnothing(qp_vec)
    # A real run's k_base is in per-model-timestep units: its rate parameters go through
    # setupParameters.jl's automatic unit conversion (declared timescale -> model_timestep)
    # before the model is instantiated, unlike the synthetic path's bare, unconverted
    # `approach()` defaults. Rescale so 1/k_base reads in years either way. The resolution
    # itself comes from helpers.dates.temporal_resolution (set in
    # src/Simulation/prepTEM.jl's getRunTEMInfo) unless overridden.
    if using_real_land && !isnothing(k_base)
        from_helpers = isnothing(helpers) ? nothing : get(get(helpers, :dates, (;)), :temporal_resolution, nothing)
        resolved_timestep = something(model_timestep, from_helpers, "day")
        k_base = k_base ./ getUnitConversionForParameter("year", resolved_timestep)
    end

    dx = _flowFanOffsets(givers)
    dy = _flowFanOffsets(takers)

    tick_labels = ["$(i). $(pool_names[i])" for i ∈ 1:n_pools]
    tick_locs = collect(1:n_pools)
    # pool-name label size: as large as fits one per row/column without adjacent labels
    # overlapping, scaled down as more pools compete for the same figure height/width
    label_fontsize = clamp(round(Int, 160 / n_pools), 8, 16)
    # asymmetric padding for the right/top name labels, growing gently with their font
    # size so a larger label still lands inside the figure limits; kept gentle because a
    # bigger margin here also shrinks the pool grid itself under aspect_ratio=:equal
    limits = (1 - 0.8, n_pools + 3.2 + (label_fontsize - 8) * 0.2)

    # fonts passed per-call rather than via plots_default, to avoid leaking into other
    # plots. fontfamily is pinned explicitly (rather than left to Plots' own default) so
    # the title/tick/guide text renders the same regardless of call order: GR carries font
    # state across figures within a session, so without this a plot drawn right after one
    # whose flow labels used _INDEX_FONT ("Helvetica Bold") could inherit that bold face.
    # A larger canvas than the default buys back some of the pixels the padding above spends.
    ax = plots_plot(; size=(1600, 1600), aspect_ratio=:equal, widen=false, legend=false,
        grid=false, xrotation=90, xticks=(tick_locs, tick_labels),
        yticks=(tick_locs, tick_labels), xlims=limits, ylims=limits,
        tickdirection=:out, left_margin=15plots_mm, bottom_margin=15plots_mm,
        top_margin=10plots_mm, right_margin=8plots_mm, fontfamily="Helvetica",
        titlefontsize=16, tickfontsize=label_fontsize, guidefontsize=13,
        title="Carbon flows: $(approach_name) ($(configuration_name), $(veg_type_name), $(n_pools) pools, $(n_flows) flows)",
        xlabel="giver (source)", ylabel="taker (target)")

    # faint cell boundaries, so the elbow corner can be read off as a matrix entry
    plots_vline!(ax, tick_locs .+ 0.5; color=:gainsboro, linewidth=0.6, label="")
    plots_hline!(ax, tick_locs .+ 0.5; color=:gainsboro, linewidth=0.6, label="")

    # pools on the diagonal, same size as the flow cells below
    half_cell = 0.43
    for pool ∈ 1:n_pools
        plots_plot!(ax, pool .+ [-half_cell, half_cell, half_cell, -half_cell, -half_cell],
            pool .+ [-half_cell, -half_cell, half_cell, half_cell, -half_cell];
            seriestype=:shape, fillcolor=:gray93, linecolor=:gray55, linewidth=1.0,
            label="")
    end

    # arrows drawn first so flow cells layer on top. Each flow's index is drawn near its
    # arrow's start point (giver + dx[flow], on the diagonal), inside the giver's own
    # box, rather than in the flow cell -- freeing the cell for T/A/M/Q alone. Offset off
    # the diagonal (the line's first, vertical leg sits exactly on it) so the label reads
    # clearly instead of sitting on top of the line.
    diag_index_fontsize = clamp(round(Int, 220 / n_pools), 12, 24)
    label_offset = half_cell * 0.35
    for flow ∈ 1:n_flows
        giver = givers[flow]
        taker = takers[flow]
        x_leg = giver + dx[flow]
        y_leg = taker + dy[flow]
        color = _CARBON_FLOW_COLORS[mod1(giver, length(_CARBON_FLOW_COLORS))]
        # elbow: giver box -> flow cell -> taker box, ending in a plain dot rather than
        # an arrowhead -- every style/size of arrowhead read as too heavy on these short
        # segments.
        plots_plot!(ax, [x_leg, x_leg, y_leg], [x_leg, y_leg, y_leg];
            color=color, linewidth=1.6, label="")
        plots_scatter!(ax, [y_leg], [y_leg]; color=color, markersize=3,
            markerstrokewidth=0, label="")
        plots_annotate!(ax, (x_leg - label_offset, x_leg,
            plots_text("$(flow)", color, :center, diag_index_fontsize, _INDEX_FONT)))
    end

    # flow cell: filled and labelled with T/A/M/Q, sized down from half_cell so crossing
    # arrows still show in the gutters. Font size is the largest that keeps the 4
    # stacked lines inside the cell, scaled down as more pools shrink the cell; the cell
    # is left unlabelled (just the color marker) when none of T/A/M/Q are available.
    half_flow_cell = has_details ? half_cell * 0.95 : half_cell * 0.75
    detail_fontsize = clamp(round(Int, 120 / n_pools), 5, 10)
    for flow ∈ 1:n_flows
        giver = givers[flow]
        taker = takers[flow]
        color = _CARBON_FLOW_COLORS[mod1(giver, length(_CARBON_FLOW_COLORS))]
        plots_plot!(ax,
            giver .+ [-half_flow_cell, half_flow_cell, half_flow_cell, -half_flow_cell, -half_flow_cell],
            taker .+ [-half_flow_cell, -half_flow_cell, half_flow_cell, half_flow_cell, -half_flow_cell];
            seriestype=:shape, fillcolor=color, fillalpha=0.9, linecolor=color,
            linewidth=0.5, label="")
        detail_text = _flowDetailLabel(flow, giver, k_base, a_vec, me_vec, qp_vec)
        isempty(detail_text) || plots_annotate!(ax, (giver, taker,
            plots_text(detail_text, _indexTextColor(color), :center, detail_fontsize, _INDEX_FONT)))
    end

    # pool names repeated on the right/top (a twin axis would need synced limits/margins)
    for i ∈ 1:n_pools
        plots_annotate!(ax, (n_pools + 0.7, i, plots_text(tick_labels[i], :gray25, :left, label_fontsize)))
        plots_annotate!(ax, (i, n_pools + 0.7, plots_text(tick_labels[i], :gray25, :left, label_fontsize, rotation=90)))
    end

    if !isnothing(file_path)
        plots_savefig(ax, file_path)
        return nothing
    end
    return ax
end
