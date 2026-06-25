module SindbadMakie
import Sindbad
using Sindbad.Setup: getParameters
using Makie
using Bonito
using Bonito: App, DOM, Grid, Card, Styles, Slider

function _slider_range(lower, upper, default)
    center = isfinite(default) && default != 0 ? default : default == 0 ? 0.0 : 1.0
    half = abs(center) > 0 ? abs(center) : 100.0

    lo = isfinite(lower) ? lower : center - 10 * half
    hi = isfinite(upper) ? upper : center + 10 * half

    if lo == hi
        lo = lo - 1.0
        hi = hi + 1.0
    end

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

function _slider_item(label_str, lo, hi, def)
    sl = Slider(_slider_range(lo, hi, def); startvalue = def)

    item = DOM.div(
        DOM.div(
            sl,
            DOM.span(map(v -> string(round(v, sigdigits=4)), sl.value))
        ),
        DOM.div(label_str)
    )

    return item, sl
end

function _build_slider_panel(title_str, items, get_range)
    sliders  = []
    elements = [DOM.div(DOM.b(title_str))]

    for (label_str, key) in items
        lo, hi, def = get_range(key)
        item, sl    = _slider_item(label_str, lo, hi, def)
        push!(elements, item)
        push!(sliders, key => sl)
    end

    content = DOM.div(elements...;
        style = Styles("padding" => "10px", "overflow-y" => "auto", "height" => "100%"))

    return content, sliders
end

function _build_output_panel(title_str, items)
    observables = []
    elements    = [DOM.div(DOM.b(title_str))]

    for (label_str, key) in items
        obs  = Observable("—")
        item = DOM.div(
            DOM.div(map(v -> v, obs)),
            DOM.div(label_str)
        )
        push!(elements, item)
        push!(observables, key => obs)
    end

    content = DOM.div(elements...;
        style = Styles("padding" => "10px", "overflow-y" => "auto", "height" => "100%"))

    return content, observables
end

function Sindbad.app_process(model, compute::Symbol; input_ranges::Dict = Dict())

    params = getParameters(model)
    io = Sindbad.getInOutModel(model, compute)
    in_paths = _flatten_paths(io[:input])
    out_paths = _flatten_paths(io[:output])

    K = keys(params)
    K_fixed = filter(k -> !(params[k].default isa Number), K)
    K_scalars = filter(k ->   params[k].default isa Number,  K)

    param_items = [
        (let
            p  = params[k]
            u  = isempty(p.units)     ? "" : " [$(p.units)]"
            ts = isempty(p.timescale) ? "" : " ($(p.timescale))"
            string(k) * u * ts
        end, k) for k in K_scalars
    ]

    params_elements = [DOM.div(DOM.b("Parameters"))]

    if length(K_fixed) > 0
        push!(params_elements,
            DOM.div("Fixed: " * join(string.(K_fixed), ", ")))
    end

    param_sliders = []
    for (label_str, key) in param_items
        p           = params[key]
        item, sl    = _slider_item(label_str, p.lower, p.upper, p.default)
        push!(params_elements, item)
        push!(param_sliders, key => sl)
    end

    params_panel = DOM.div(params_elements...;
        style = Styles("padding" => "10px", "overflow-y" => "auto", "height" => "100%"));

    in_items = [(path, leaf) for (path, leaf) in in_paths]

    inputs_panel, input_sliders = _build_slider_panel("Inputs", in_items,
        leaf -> if haskey(input_ranges, leaf)
            r = input_ranges[leaf]; (r[1], r[2], r[3])
        else
            (-Inf, Inf, 0.0)
        end)

    out_items = [(path, leaf) for (path, leaf) in out_paths]
    outputs_panel, output_observables = _build_output_panel("Outputs", out_items)

    fig = Figure()
    ax  = Axis(fig[1, 1]; title="Plot", xlabel="input", ylabel="output")
    text!(ax, 0.5, 0.5; text="placeholder", align=(:center, :center), space=:relative)

    app = App() do
        # Make Makie responsive
        fig.scene.viewport[] = Rect2f(0, 0, 800, 500)
        fig.scene.px_area[] = Rect2f(0, 0, 800, 500)

        title_card = Card(
            DOM.div(
                DOM.b(string(nameof(typeof(model)))),
                DOM.span(" — $(string(io[:approach]))")
            );
            style=Styles(
                "grid-area" => "title",
                "padding" => "10px"
            )
        )

        params_card = Card(
            params_panel;
            style=Styles(
                "grid-area" => "params",
                "overflow" => "auto",
                "min-width" => "0"
            )
        )

        io_div = DOM.div(
            Card(
                inputs_panel;
                style=Styles(
                    "flex" => "1",
                    "min-width" => "0"
                )
            ),

            Card(
                outputs_panel;
                style=Styles(
                    "flex" => "1",
                    "min-width" => "0"
                )
            );

            style=Styles(
                "grid-area" => "io",
                "display" => "flex",
                "gap" => "16px",
                "flex-wrap" => "wrap"
            )
        )

        plot_card = Card(
            DOM.div(
                fig;
                style=Styles(
                    "width" => "100%",
                    "height" => "100%"
                )
            );

            style=Styles(
                "grid-area" => "plot",
                "min-height" => "400px",
                "overflow" => "hidden"
            )
        )

        grid = Grid(
            title_card,
            params_card,
            io_div,
            plot_card;

            columns = "320px 1fr",
            rows = "auto auto 1fr",

            areas = """
            'title title'
            'params io'
            'params plot'
            """,

            style = Styles(
                "display" => "grid",
                "gap" => "20px",          # ← space between IO and plot
                "height" => "100%",

                # Responsive
                "@media (max-width: 768px)" => Dict(
                    "grid-template-columns" => "1fr",
                    "grid-template-rows" =>
                        "auto auto auto auto",

                    "grid-template-areas" =>
                        """
                        'title'
                        'params'
                        'io'
                        'plot'
                        """
                )
            )
        )

        DOM.div(
            grid;

            style=Styles(
                "height" => "100vh",
                "padding" => "20px",
                "box-sizing" => "border-box",

                # Slider expansion
                ".bonito-slider" => Dict(
                    "width" => "100%"
                ),

                "input[type=range]" => Dict(
                    "width" => "100%"
                ),

                # Stack INPUT/OUTPUT on phones
                "@media (max-width: 768px)" => Dict(
                    ".io" => Dict(
                        "flex-direction" => "column"
                    )
                )
            )
        )
    end

    Bonito.Server(app, "0.0.0.0", 8080)
    Bonito.browser_display()
    # return app, param_sliders, input_sliders, output_observables
    return app
end

end