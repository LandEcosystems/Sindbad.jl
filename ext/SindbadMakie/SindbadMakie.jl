module SindbadMakie
import Sindbad
using Sindbad.Setup: getParameters
using Makie

function _slider_range(lower, upper, default)
    center = isfinite(default) && default != 0 ? default : default == 0 ? 0.0 : 1.0
    half = abs(center) > 0 ? abs(center) : 100.0

    lo = isfinite(lower) ? lower : center - 10 * half
    hi = isfinite(upper) ? upper : center + 10 * half

    step = default isa Integer ? 1 : (hi - lo) / 200
    lo_anchored = default - floor((default - lo) / step) * step

    return lo_anchored:step:hi
end

function _flatten_paths(node, prefix="")
    result = Pair{String, Symbol}[]
    for entry in node
        if entry isa Pair
            key  = string(entry.first)
            path = prefix == "" ? key : "$(prefix).$(key)"
            append!(result, _flatten_paths(entry.second, path))
        elseif entry isa Symbol
            path = prefix == "" ? string(entry) : "$(prefix).$(entry)"
            push!(result, path => entry)
        end
    end
    return result
end
function _build_slider_rows!(gl, start_row, items, get_range)
    sliders = map(enumerate(items)) do (i, (label_str, key))
        lo, hi, def = get_range(key)
        r = i - 1

        sl = Slider(gl[start_row + r*2, 1],
            range = _slider_range(lo, hi, def),
            startvalue = def)

        Label(gl[start_row + r*2, 2],
            @lift(string(round($(sl.value), sigdigits=4)));
            halign = :left, tellwidth = false, fontsize = 14)

        Label(gl[start_row + r*2 + 1, 1:2], label_str;
            halign = :left, tellwidth = false,
            fontsize = 14, #color = (:gray, 0.8)
            )

        key => sl
    end

    return sliders
end

function _build_output_rows!(gl, start_row, items)
    labels = map(enumerate(items)) do (i, (label_str, key))
        r = i - 1

        lbl = Label(gl[start_row + r*2, 1:2], "—";
            halign = :left, tellwidth = false, fontsize = 14)

        Label(gl[start_row + r*2 + 1, 1:2], label_str;
            halign = :left, tellwidth = false,
            fontsize = 14, color = (:gray, 0.9))

        key => lbl
    end
    return labels
end

function Sindbad.dash_plot(model, compute::Symbol; input_ranges::Dict = Dict())

    params = getParameters(model)
    io = Sindbad.getInOutModel(model, compute)
    in_paths = _flatten_paths(io[:input])
    out_paths = _flatten_paths(io[:output])

    K = keys(params)
    K_fixed = filter(k -> !(params[k].default isa Number), K)
    K_scalars = filter(k ->   params[k].default isa Number,  K)

    fig = Figure(; size = (1100, 600))

    Label(fig[1, 1:3],
        rich("$(string(io[:approach]))"; font=:bold, fontsize=18);
        halign = :left, tellwidth = false)

    params_gl = fig[2, 1] = GridLayout()
    inputs_gl = fig[1, 2] = GridLayout()
    outputs_gl = fig[1, 3] = GridLayout()
    plot_gl = fig[2, 2:3] = GridLayout()

    colsize!(fig.layout, 1, Relative(0.25))
    colsize!(fig.layout, 2, Relative(0.35))
    colsize!(fig.layout, 3, Relative(0.40))

    prow = 1
    Label(params_gl[prow, 1:2],
        rich(rich("Parameters"; font=:bold));
        halign = :left, tellwidth = false)
    prow += 1

    if length(K_fixed) > 0
        Label(params_gl[prow, 1:2],
            rich(rich("Fixed: "; color=:tomato, font=:bold),
                 rich(join(string.(K_fixed), ", "); color=:tomato));
            halign = :left, tellwidth = false)
        prow += 1
    end

    colsize!(params_gl, 1, Relative(0.7))
    colsize!(params_gl, 2, Relative(0.3))

    param_items = [
        (let
            p = params[k]
            u  = isempty(p.units) ? "" : " [$(p.units)]"
            ts = isempty(p.timescale) ? "" : " ($(p.timescale))"
            string(k) * u * ts
        end, k) for k in K_scalars
    ]

    param_sliders = _build_slider_rows!(params_gl, prow, param_items,
        k -> (params[k].lower, params[k].upper, params[k].default))

    irow = 1
    Label(inputs_gl[irow, 1:2],
        rich(rich("Inputs"; font=:bold));
        halign = :left, tellwidth = false)
    irow += 1

    colsize!(inputs_gl, 1, Relative(0.7))
    colsize!(inputs_gl, 2, Relative(0.3))

    in_items = [(path, leaf) for (path, leaf) in in_paths]

    input_sliders = _build_slider_rows!(inputs_gl, irow, in_items,
        leaf -> if haskey(input_ranges, leaf)
            r = input_ranges[leaf]; (r[1], r[2], r[3])
        else
            (-Inf, Inf, 0.0)
        end)

    orow = 1
    Label(outputs_gl[orow, 1:2],
        rich(rich("Outputs"; font=:bold));
        halign = :left, tellwidth = false)
    orow += 1

    out_items = [(path, leaf) for (path, leaf) in out_paths]
    output_labels = _build_output_rows!(outputs_gl, orow, out_items)

    ax = Axis(plot_gl[1, 1];
        title  = "Plot",
        xlabel = "input",
        ylabel = "output")
    text!(ax, 0.5, 0.5;
        text = "placeholder", align = (:center, :center), space = :relative)

    return fig, param_sliders, input_sliders, output_labels
end

end