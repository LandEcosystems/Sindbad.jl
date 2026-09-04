# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.Visualization: plotCarbonFlows

"""
    _CARBON_FLOW_COLORS

Colors cycled over the giver pools, so the arrows leaving one pool share a color and
the ones crossing the same cell can be told apart.
"""
const _CARBON_FLOW_COLORS = ["#1f77b4", "#d62728", "#2ca02c", "#9467bd", "#ff7f0e",
    "#17becf", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22"]

"""
    _INDEX_FONT

The font the flow index is drawn in, bold so the number carries against its colored cell.

A family name rather than Plots' `:bold`, which sets the family to `"bold"` and leaves GR
looking for a `bold.ttf` it does not have, silently falling back to the regular weight.
`"Helvetica Bold"` is one of GR's built-in faces, so it resolves without a system font.
"""
const _INDEX_FONT = "Helvetica Bold"

"""
    _indexTextColor(hex_color)

Return `:white` or `:black`, whichever reads on a cell filled with `hex_color`.

The palette runs from a dark blue to a light yellow-green, so a single text color is
legible on some of it and not the rest. The threshold sits above the orange, which
carries white better than black despite its luminance.
"""
function _indexTextColor(hex_color)
    red = parse(Int, hex_color[2:3]; base=16)
    green = parse(Int, hex_color[4:5]; base=16)
    blue = parse(Int, hex_color[6:7]; base=16)
    return 0.299red + 0.587green + 0.114blue < 160 ? :white : :black
end

"""
    _carbonPoolNames(approach)

Return `(pool_names, configuration_name)` for a `cCycleBase` approach: the leaf pool
names of its pool structure, in `cEco` index order, and the name of the configuration
they came from.

Flattening is `getPoolInformation`, the same call `generatedPoolNames` makes, so the
order here is the order `setPoolsInfo` produces at run time and a name's position is
its `cEco` index.
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
    _flowFanOffsets(keys_of_flows)

Return one small offset per flow, spreading the flows that share a key evenly about
zero.

Every arrow leaving the same giver runs down the same column, and every arrow arriving
at the same taker runs along the same row, so without this the segments lie on top of
each other. Under CASA that is 22 arrows over 14 columns.
"""
function _flowFanOffsets(keys_of_flows)
    # A group spans this band whatever its size, so the six arrows arriving at cSoilSlow
    # separate as well as the two arriving at cMicSurf. Dividing by the member count
    # instead would tighten the fan exactly where it is needed most.
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
    plotCarbonFlows(approach)
    plotCarbonFlows(approach, file_path)

Draw the carbon pool flow topology of a `cCycleBase` approach as a square
giver-by-taker plot, with one labelled arrow per carbon flow.

# Arguments
- `approach`: a `cCycleBase` approach, as a type or an instance, e.g. `cCycleBase_CASA`
- `file_path`: where to save the figure, or `nothing` to return it without saving.
  Defaults to `tmp_<approach>.png` in the working directory when the approach is the
  only argument

# Returns
- The plot object.

# Description
- The pools sit on the diagonal, in `cEco` index order, named on all four sides.
- x is the giver, y is the taker, matching the `[taker, giver]` orientation of
  `cFlowMatrix` read as (column, row).
- Each flow is an elbow leaving the giver's box, turning at the matrix cell that
  carries it, and arriving at the taker's box. The cell it turns in is filled and
  carries the flow index.
- The flow index is the position in `c_flow_order`, so it is the index into
  `c_flow_A_vec`, `c_flow_QP_vec`, `c_flow_ME_vec` and the `d_cFlow` output dimension.

# Examples
```jldoctest
julia> using Sindbad, Plots

julia> # Draw the CASA carbon flow topology into tmp_cCycleBase_CASA.png
julia> # plotCarbonFlows(cCycleBase_CASA)

julia> # Choose the file name
julia> # plotCarbonFlows(cCycleBase_CASA, "casa_flows.png")

julia> # Get the plot object back without writing anything
julia> # plotCarbonFlows(cCycleBase_CASA, nothing)
```

# Notes
- Needs no experiment, no forcing and no run: the topology is declared by the approach
  through `cFlowEdges` and `poolConfiguration`.
- The pool structure is the one the approach is written against. An experiment whose
  model structure JSON writes its pools out in full may configure a different one.
"""
function plotCarbonFlows(approach, file_path, ::VisualizationPlots)
    approach_name = nameof(approach isa Type ? approach : typeof(approach))
    pool_names, configuration_name = _carbonPoolNames(approach)
    flow_matrix = cFlowMatrix(approach, pool_names)
    n_pools = length(pool_names)

    print_info(plotCarbonFlows, @__FILE__, @__LINE__, "plotting carbon flows of $(approach_name) over $(n_pools) pools", n_f=4)

    # walk the matrix in flow order, so flow k is drawn with the label k
    n_flows = maximum(flow_matrix)
    givers = zeros(Int, n_flows)
    takers = zeros(Int, n_flows)
    for taker ∈ 1:n_pools, giver ∈ 1:n_pools
        flow = flow_matrix[taker, giver]
        flow == 0 && continue
        givers[flow] = giver
        takers[flow] = taker
    end

    dx = _flowFanOffsets(givers)
    dy = _flowFanOffsets(takers)

    tick_labels = ["$(i). $(pool_names[i])" for i ∈ 1:n_pools]
    tick_locs = collect(1:n_pools)
    # The room the right and top names need is all above and to the right of the pools,
    # so the padding is asymmetric. Both axes still span the same number of units, which
    # is what keeps the plot square under aspect_ratio=:equal.
    limits = (1 - 0.8, n_pools + 3.2)

    # Fonts are passed here rather than through plots_default, which would leak them
    # into every other figure drawn in the same session.
    ax = plots_plot(; size=(1400, 1400), aspect_ratio=:equal, widen=false, legend=false,
        grid=false, xrotation=90, xticks=(tick_locs, tick_labels),
        yticks=(tick_locs, tick_labels), xlims=limits, ylims=limits,
        tickdirection=:out, left_margin=15plots_mm, bottom_margin=15plots_mm,
        top_margin=8plots_mm, right_margin=8plots_mm,
        titlefontsize=14, tickfontsize=8, guidefontsize=11,
        title="Carbon flows: $(approach_name) ($(configuration_name), $(n_pools) pools, $(n_flows) flows)",
        xlabel="giver (source)", ylabel="taker (target)")

    # faint cell boundaries, so the elbow corner can be read off as a matrix entry
    plots_vline!(ax, tick_locs .+ 0.5; color=:gainsboro, linewidth=0.6, label="")
    plots_hline!(ax, tick_locs .+ 0.5; color=:gainsboro, linewidth=0.6, label="")

    # The pools, on the diagonal, drawn the same size as the flow cells below so the
    # whole thing reads as one matrix rather than as markers with blocks around them.
    half_cell = 0.43
    for pool ∈ 1:n_pools
        plots_plot!(ax, pool .+ [-half_cell, half_cell, half_cell, -half_cell, -half_cell],
            pool .+ [-half_cell, -half_cell, half_cell, half_cell, -half_cell];
            seriestype=:shape, fillcolor=:gray93, linecolor=:gray55, linewidth=1.0,
            label="")
    end

    # Arrows first, then the cells on top of them, so an arrow crossing a cell it does
    # not belong to cannot run through that cell's number.
    for flow ∈ 1:n_flows
        giver = givers[flow]
        taker = takers[flow]
        x_leg = giver + dx[flow]
        y_leg = taker + dy[flow]
        color = _CARBON_FLOW_COLORS[mod1(giver, length(_CARBON_FLOW_COLORS))]
        # leave the giver's box, turn at the cell that carries this flow, arrive at the
        # taker's box. Both ends are pools, so the arrow reads as source to target.
        plots_plot!(ax, [x_leg, x_leg, y_leg], [x_leg, y_leg, y_leg];
            color=color, linewidth=1.6, arrow=:closed, label="")
    end

    # The cell each flow turns in, filled and numbered. A giver-to-taker pair carries
    # exactly one flow, so the cell needs no key beyond its own number. Drawn as a shape
    # rather than a marker so it stays one cell wide whatever the pool count, and sized
    # just under the cell so crossing arrows still show in the gutters.
    # Half the pool box, so the colored cell reads as a marker on the flow rather than as
    # a block filling the grid, and more of the arrows underneath stay visible.
    half_flow_cell = half_cell / 2
    index_fontsize = clamp(round(Int, 150 / n_pools), 9, 18)
    for flow ∈ 1:n_flows
        giver = givers[flow]
        taker = takers[flow]
        color = _CARBON_FLOW_COLORS[mod1(giver, length(_CARBON_FLOW_COLORS))]
        plots_plot!(ax,
            giver .+ [-half_flow_cell, half_flow_cell, half_flow_cell, -half_flow_cell, -half_flow_cell],
            taker .+ [-half_flow_cell, -half_flow_cell, half_flow_cell, half_flow_cell, -half_flow_cell];
            seriestype=:shape, fillcolor=color, fillalpha=0.9, linecolor=color,
            linewidth=0.5, label="")
        plots_annotate!(ax, (giver, taker,
            plots_text("$(flow)", _indexTextColor(color), :center, index_fontsize,
                _INDEX_FONT)))
    end

    # the same names again on the right and the top, as annotations: a twin axis would
    # be a linked subplot whose limits and margins have to be kept in step with these
    for i ∈ 1:n_pools
        plots_annotate!(ax, (n_pools + 0.7, i, plots_text(tick_labels[i], :gray25, :left, 8)))
        plots_annotate!(ax, (i, n_pools + 0.7, plots_text(tick_labels[i], :gray25, :left, 8, rotation=90)))
    end

    if !isnothing(file_path)
        plots_savefig(ax, file_path)
    end
    return ax
end
