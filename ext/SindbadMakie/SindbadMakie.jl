module SindbadMakie
import Sindbad
using Sindbad.Setup: getParameters
using Makie

function Sindbad.dash_plot(model)
    params = getParameters(model)
    K = keys(params)
    K_fixed   = filter(k -> !(params[k].default isa Number), K)
    K_scalars = filter(k ->   params[k].default isa Number,  K)
    n_fixed   = length(K_fixed)
    n_scalars = length(K_scalars)
    fig = Figure(; size = (600, 80 + 25 + n_fixed * 25 + n_scalars * 60))

    Label(fig[1, 1:3], string(nameof(typeof(model)));
        fontsize = 18, font = :bold, tellwidth = false)

    row = 2

    if n_fixed > 0
        Label(fig[row, 1:3],
            rich(rich("Fixed: "; color=:tomato, font=:bold));
            halign = :left, tellwidth = false)
        row += 1

        for k in K_fixed
            p  = params[k]
            u  = isempty(p.units)     ? "" : " [$(p.units)]"
            ts = isempty(p.timescale) ? "" : " ($(p.timescale))"

            Label(fig[row, 1:3],
                rich(
                    rich("  $(string(k))"; color=:tomato, font=:bold),
                    rich(" ($(nameof(typeof(p.default))))"; color=:tomato),
                    rich(u * ts; color=(:gray, 0.7))
                );
                halign = :left, tellwidth = false)
            row += 1
        end
    end

    sliders = map(enumerate(K_scalars)) do (i, k)
        p  = params[k]
        u  = isempty(p.units)     ? "" : " [$(p.units)]"
        ts = isempty(p.timescale) ? "" : " ($(p.timescale))"

        Label(fig[row + i - 1, 1],
            rich(
                rich(string(k); font=:bold),
                rich(u * ts; color=(:gray, 0.7))
            );
            halign = :right, tellwidth = true)

        sl = Slider(fig[row + i - 1, 2],
            range = _slider_range(p.lower, p.upper, p.default),
            startvalue = p.default)

        Label(fig[row + i - 1, 3],
            @lift(string(round($(sl.value), sigdigits=4)));
            halign = :left, width = 50)

        k => sl
    end

    return fig
end

function _slider_range(lower, upper, default)
    center = isfinite(default) && default != 0 ? default : default == 0 ? 0.0 : 1.0
    half = abs(center) > 0 ? abs(center) : 100.0

    lo = isfinite(lower) ? lower : center - 10 * half
    hi = isfinite(upper) ? upper : center + 10 * half

    step = default isa Integer ? 1 : (hi - lo) / 200
    # Anchor grid to default so it's always an exact step
    lo_anchored = default - floor((default - lo) / step) * step

    return lo_anchored:step:hi
end

end