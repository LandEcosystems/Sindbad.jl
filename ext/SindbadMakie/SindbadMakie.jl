module SindbadMakie
import Sindbad
import SindbadTEM
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

function _path_symbols(path)
    return Symbol.(split(path, "."))
end

function _nested_get(value, path)
    for key in path
        hasproperty(value, key) || return nothing
        value = getproperty(value, key)
    end
    return value
end

function _nested_set(value, path, replacement)
    isempty(path) && return replacement

    key = first(path)
    hasproperty(value, key) || return value
    child = _nested_set(getproperty(value, key), path[2:end], replacement)
    return merge(value, NamedTuple{(key,)}((child,)))
end

function _context_get(forcing, land, path)
    parts = _path_symbols(path)
    isempty(parts) && return nothing

    root, remainder = first(parts), parts[2:end]
    value = root === :forcing ? forcing : root === :land ? land : nothing
    return isnothing(value) ? nothing : _nested_get(value, remainder)
end

function _context_set(forcing, land, path, replacement)
    parts = _path_symbols(path)
    isempty(parts) && return forcing, land

    root, remainder = first(parts), parts[2:end]
    if root === :forcing
        forcing = _nested_set(forcing, remainder, replacement)
    elseif root === :land
        land = _nested_set(land, remainder, replacement)
    end
    return forcing, land
end

function _run_define_precompute(model, forcing, land, helpers)
    land = SindbadTEM.Processes.define(model, forcing, land, helpers)
    return SindbadTEM.Processes.precompute(model, forcing, land, helpers)
end

function _model_with_parameters(model, sliders)
    isempty(sliders) && return model

    params = getParameters(model)
    values = map(keys(params)) do key
        haskey(sliders, key) ? sliders[key].value[] : getproperty(model, key)
    end
    return typeof(model)(values...)
end

function _numeric_value(value)
    return value isa Number ? Float64(value) : NaN
end

const _CATEGORY_COLORS = Dict(
    "forcing" => :steelblue,
    "states" => :seagreen,
    "diagnostics" => :darkorange,
    "pools" => :firebrick,
    "fluxes" => :mediumpurple,
    "constants" => :slategray,
    "properties" => :goldenrod,
)

function _category_for_path(path)
    parts = split(path, ".")
    return parts[1] == "land" && length(parts) > 1 ? parts[2] : parts[1]
end

function _category_color(category)
    return get(_CATEGORY_COLORS, category, :gray)
end

function _parent_sized_figure(fig)
    if isdefined(Main, :WGLMakie)
        return Main.WGLMakie.WithConfig(fig; resize_to=:parent)
    end
    return fig
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
        lo, hi, def = get_range(label_str, key)
        item, sl    = _slider_item(label_str, lo, hi, def)
        push!(elements, item)
        push!(sliders, label_str => sl)
    end

    content = DOM.div(elements...;
        style = Styles("padding" => "10px", "overflow-y" => "auto", "height" => "100%"))

    return content, sliders
end

function _build_input_panel(title_str, items, fixed_paths, get_range, get_value)
    sliders  = Pair{String, Any}[]
    fixed_values = Pair{String, Any}[]
    categories = Dict{String, Vector{Tuple{String, Symbol}}}()
    category_order = String[]

    for item in items
        path = first(item)
        category = _category_for_path(path)
        if !haskey(categories, category)
            categories[category] = Tuple{String, Symbol}[]
            push!(category_order, category)
        end
        push!(categories[category], item)
    end

    category_cards = Any[]

    for category in category_order
        elements = [DOM.div(DOM.b(category))]
        for (label_str, key) in categories[category]
            display_label = split(label_str, ".")[end]
            if label_str in fixed_paths
                value = get_value(label_str, key)
                value_observable = Observable(string(value))
                item = DOM.div(
                    DOM.div(map(v -> v, value_observable)),
                    DOM.div(display_label)
                )
                push!(elements, item)
                push!(fixed_values, label_str => value_observable)
            else
                lo, hi, def = get_range(label_str, key)
                item, sl = _slider_item(display_label, lo, hi, def)
                push!(elements, item)
                push!(sliders, label_str => sl)
            end
        end

        push!(category_cards, Card(
            DOM.div(elements...;
                style=Styles("display" => "flex", "flex-direction" => "column", "gap" => "8px"));
            style=Styles(
                "min-width" => "0",
                "flex" => "1 1 220px",
                "padding" => "10px",
                "border-top" => "4px solid $(_category_color(category))"
            )
        ))
    end

    content = DOM.div(
        DOM.div(DOM.b(title_str)),
        DOM.div(category_cards...;
            style=Styles("display" => "flex", "flex-wrap" => "wrap", "gap" => "10px"));
        style=Styles("padding" => "10px", "overflow-y" => "auto", "height" => "100%")
    )

    return content, sliders, fixed_values
end

function _build_output_panel(title_str, items)
    observables = []
    categories = Dict{String, Vector{Tuple{String, Symbol}}}()
    category_order = String[]

    for item in items
        path = first(item)
        category = _category_for_path(path)
        if !haskey(categories, category)
            categories[category] = Tuple{String, Symbol}[]
            push!(category_order, category)
        end
        push!(categories[category], item)
    end

    category_cards = Any[]

    for category in category_order
        elements = [DOM.div(DOM.b(category))]
        for (label_str, key) in categories[category]
            obs  = Observable("—")
            display_label = split(label_str, ".")[end]
            item = DOM.div(
                DOM.div(map(v -> v, obs)),
                DOM.div(display_label)
            )
            push!(elements, item)
            push!(observables, label_str => obs)
        end

        push!(category_cards, Card(
            DOM.div(elements...;
                style=Styles("display" => "flex", "flex-direction" => "column", "gap" => "8px"));
            style=Styles(
                "min-width" => "0",
                "flex" => "1 1 160px",
                "padding" => "10px",
                "border-top" => "4px solid $(_category_color(category))"
            )
        ))
    end

    content = DOM.div(
        DOM.div(DOM.b(title_str)),
        DOM.div(category_cards...;
            style=Styles("display" => "flex", "flex-wrap" => "wrap", "gap" => "10px"));
        style=Styles("padding" => "10px", "overflow-y" => "auto", "height" => "100%")
    )

    return content, observables
end

function Sindbad.app_process(model, compute::Symbol;
    input_ranges::Dict = Dict(), forcing = (;), land = (;), helpers = (;))

    params = getParameters(model)
    io = Sindbad.getInOutModel(model, compute)
    in_paths = _flatten_paths(io[:input])
    out_paths = _flatten_paths(io[:output])

    # Initialize fields created by define/precompute before deriving slider defaults.
    initialized_land = _run_define_precompute(model, forcing, land, helpers)
    # Land-side inputs are initialized by the model context and remain fixed for
    # the current run. Only forcing inputs are user-adjustable sliders.
    fixed_input_paths = [
        path for (path, _) in _flatten_paths(io[:input])
        if startswith(path, "land.")
    ]

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
        style = Styles(
            "padding" => "10px",
            "overflow-y" => "auto",
            "height" => "100%",
            "display" => "flex",
            "flex-direction" => "column",
            "gap" => "8px"
        ));

    in_items = [(path, leaf) for (path, leaf) in in_paths]

    inputs_panel, input_sliders, fixed_input_values = _build_input_panel(
        "Inputs", in_items, fixed_input_paths,
        (path, leaf) -> begin
            value = _context_get(forcing, initialized_land, path)
            default = value isa Number ? value : 0.0
            if haskey(input_ranges, leaf)
                r = input_ranges[leaf]
                (r[1], r[2], r[3])
            else
                (-Inf, Inf, default)
            end
        end,
        (path, _) -> _context_get(forcing, initialized_land, path))

    out_items = [(path, leaf) for (path, leaf) in out_paths]
    outputs_panel, output_observables = _build_output_panel("Outputs", out_items)
    param_slider_map = Dict(param_sliders)
    input_slider_map = Dict(input_sliders)
    fixed_input_value_map = Dict(fixed_input_values)
    output_observable_map = Dict(output_observables)

    fig = Figure()
    ax  = Axis(fig[1, 1];
        title="Outputs",
        xlabel="output",
        ylabel="value"
    )
    output_values = Observable(fill(NaN, length(out_paths)))
    output_labels = [string(key) for (_, key) in out_paths]
    output_colors = [_category_color(_category_for_path(path)) for (path, _) in out_paths]
    if !isempty(out_paths)
        barplot!(ax, 1:length(out_paths), output_values; color=output_colors)
        ax.xticks = (1:length(out_paths), output_labels)
        autolimits!(ax)
        on(output_values) do _
            ylims!(ax, nothing, nothing)
        end
    end

    function update_outputs!()
        current_model = _model_with_parameters(model, param_slider_map)
        current_forcing, current_land = forcing, land

        for (path, _) in in_paths
            if !(path in fixed_input_paths)
                value = input_slider_map[path].value[]
                current_forcing, current_land =
                    _context_set(current_forcing, current_land, path, value)
            end
        end

        current_land = _run_define_precompute(
            current_model, current_forcing, current_land, helpers)

        for path in fixed_input_paths
            fixed_value = _context_get(current_forcing, current_land, path)
            fixed_input_value_map[path][] = string(fixed_value)
        end

        # Some land inputs, such as states created by define, only exist now.
        for (path, _) in in_paths
            if startswith(path, "land.") && !(path in fixed_input_paths)
                value = input_slider_map[path].value[]
                current_forcing, current_land =
                    _context_set(current_forcing, current_land, path, value)
            end
        end

        current_land = SindbadTEM.Processes.compute(
            current_model, current_forcing, current_land, helpers)

        output_result = map(out_paths) do (path, _)
            value = _context_get(current_forcing, current_land, path)
            _numeric_value(value)
        end
        output_values[] = output_result

        for ((path, _), value) in zip(out_paths, output_result)
            output_observable_map[path][] = isfinite(value) ? string(value) : "—"
        end
    end

    for (_, slider) in param_sliders
        on(slider.value) do _
            update_outputs!()
        end
    end
    for (_, slider) in input_sliders
        on(slider.value) do _
            update_outputs!()
        end
    end

    try
        update_outputs!()
    catch error
        @warn "Unable to evaluate $(nameof(typeof(model))) for the initial plot" exception=(error, catch_backtrace())
    end

    app = App(title="SindbadApp") do
        parent_sized_fig = _parent_sized_figure(fig)

        theme_button = DOM.button(
            "Dark mode";
            onclick=js"event => {
                const dark = document.documentElement.dataset.theme !== 'dark';
                document.documentElement.dataset.theme = dark ? 'dark' : 'light';
                document.documentElement.style.colorScheme = dark ? 'dark' : 'light';
                document.body.style.backgroundColor = dark ? '#0A0C0D' : '#ffffff';
                document.body.style.color = dark ? '#f5f7fa' : '#0A0C0D';
                event.currentTarget.textContent = dark ? 'Light mode' : 'Dark mode';
            }",
            style=Styles(
                "margin-left" => "auto",
                "padding" => "6px 10px",
                "cursor" => "pointer"
            )
        )

        title_card = Card(
            DOM.div(
                # DOM.b(string(nameof(typeof(model)))),
                DOM.span("$(string(io[:approach]))"),
                theme_button;
                style=Styles(
                    "display" => "flex",
                    "align-items" => "center",
                    "gap" => "8px"
                )
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
                    "flex-basis" => "360px",
                    "min-width" => "0"
                )
            ),

            Card(
                outputs_panel;
                style=Styles(
                    "flex" => "1",
                    "flex-basis" => "360px",
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
                parent_sized_fig;
                style=Styles(
                    "width" => "100%",
                    "height" => "100%",
                    "min-height" => "360px",
                    "display" => "flex",
                    "flex" => "1"
                )
            );

            style=Styles(
                "grid-area" => "plot",
                "min-height" => "400px",
                "min-width" => "0",
                "height" => "100%",
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
                "min-width" => "0",
                "min-height" => "0",

                # Responsive
                "@media (max-width: 1100px)" => Dict(
                    "grid-template-columns" => "280px 1fr"
                ),
                "@media (max-width: 900px)" => Dict(
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
                "max-width" => "100%",
                "padding" => "20px",
                "box-sizing" => "border-box",
                "overflow-x" => "hidden",

                # Slider expansion
                ".bonito-slider" => Dict(
                    "width" => "100%"
                ),

                "input[type=range]" => Dict(
                    "width" => "100%"
                ),

                "@media (max-width: 900px)" => Dict(
                    "padding" => "12px"
                )
            )
        )
    end

    Bonito.Server(app, "0.0.0.0", 0)
    Bonito.browser_display()
    # return app, param_sliders, input_sliders, output_observables
    return app
end

end