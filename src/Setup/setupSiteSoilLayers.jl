export setSiteSoilLayers

# Keep the Aug14 geometry: a 5 cm minimum, exact bottom depth, no 10 m cap.
function siteSoilLayerThicknesses(depth_m, boundaries_m)
    boundaries = Float64.(collect(boundaries_m))
    isempty(boundaries) && throw(ArgumentError("boundaries_m cannot be empty"))
    all(x -> isfinite(x) && x > 0, boundaries) && all(diff(boundaries) .> 0) ||
        throw(ArgumentError("boundaries_m must be finite, positive, and strictly increasing"))
    validSiteSoilDepth(depth_m) || throw(ArgumentError("Invalid soil depth: $depth_m"))
    effective = max(Float64(depth_m), first(boundaries))
    bottoms = vcat(boundaries[boundaries .< effective], effective)
    return diff(vcat(0.0, bottoms)) .* 1000, effective
end

validSiteSoilDepth(x) = x isa Real && isfinite(x) && x > 0 && x != 9999

"""
    setSiteSoilLayers(info, forcing;
        depth_variables=("f_depth_site", "soil_depth_CLM"),
        boundaries_m=[0.05, 0.20, 0.50, 1.00, 2.00, 5.00, 10.00],
        initial_water_mm=100.0)

Rebuild a freshly prepared experiment with site-specific soil-water layers.
Call after `getForcing(info)` and before `prepTEM(forcing, info)`. Exactly one
site must be selected. Match that site's coordinate to the original dataset at
`info.experiment.data_settings.forcing.default_forcing.data_path`.

Read the first time sample of each depth variable in priority order, in metres.
Accept `(site,)`, `(site, time)`, or reversed dimension order; reject missing,
nonfinite, nonpositive and 9999 depths. These variables need not be model inputs.
Use the first valid depth, preserve the exact profile bottom (minimum 5 cm by
default), and initialize each layer with `initial_water_mm` of water.

Returns a new `info`, rebuilding pools, land initialization, output dimensions,
and optimization metadata from retained setup inputs. Use only before simulation
or parameter updates: this resets derived state to its configured initial values.
The supplied `info`, `forcing`, and dataset are not modified. Provenance is stored
in `info.site_soil_layers`; saved info is refreshed when saving is enabled.
"""
function setSiteSoilLayers(info, forcing;
        depth_variables=("f_depth_site", "soil_depth_CLM"),
        boundaries_m=[0.05, 0.20, 0.50, 1.00, 2.00, 5.00, 10.00],
        initial_water_mm=100.0)
    hasproperty(info, :setup_input) || throw(ArgumentError(
        "Recreate info with getExperimentInfo before calling setSiteSoilLayers"))
    isfinite(initial_water_mm) && initial_water_mm >= 0 ||
        throw(ArgumentError("initial_water_mm must be finite and nonnegative"))
    axes = Dict(forcing.helpers.axes)
    haskey(axes, :site) || throw(ArgumentError("Expected a named site dimension"))
    length(axes[:site]) == 1 || throw(ArgumentError(
        "setSiteSoilLayers requires exactly one selected site; prepare each site separately"))
    site = string(only(axes[:site]))
    path = getAbsDataPath(info, info.experiment.data_settings.forcing.default_forcing.data_path)
    # DataLoaders is included after Setup; resolve it at call time to avoid a module cycle.
    loaders = getproperty(parentmodule(@__MODULE__), :DataLoaders)
    dataset = loaders.YAXArrays.open_dataset(path)
    site_names = string.(collect(dataset.site.val))
    matches = findall(==(site), site_names)
    length(matches) == 1 || throw(ArgumentError("Expected one match for site $site in $path"))
    site_index = only(matches)
    time_dim = Symbol(info.experiment.data_settings.forcing.data_dimension.time)
    depth = nothing
    source = nothing
    for name in depth_variables
        key = Symbol(name)
        haskey(dataset.cubes, key) || continue
        cube = dataset.cubes[key]
        names = Tuple(loaders.YAXArrayBase.dimnames(cube))
        :site in names || throw(ArgumentError("$name must have a site dimension"))
        all(n -> n in (:site, time_dim), names) ||
            throw(ArgumentError("$name must contain only site and optional time dimensions"))
        indices = map(n -> n == :site ? site_index : 1, names)
        value = cube[indices...]
        value = value isa AbstractArray ? only(value) : value
        if validSiteSoilDepth(value)
            depth, source = Float64(value), String(name)
            break
        end
    end
    isnothing(depth) && throw(ArgumentError(
        "No valid soil depth for $site in $path; tried $(join(depth_variables, ", "))"))
    layers, effective = siteSoilLayerThicknesses(depth, boundaries_m)
    seed = deepcopy(info.setup_input)
    seed = @set seed.settings.model_structure.pools.water.components.soilW = Any[layers, initial_water_mm]
    rebuilt = setupInfo(seed)
    provenance = (; site, data_path=path, source_variable=source, raw_depth_m=depth,
        effective_depth_m=effective, layer_thickness_mm=layers, initial_water_mm)
    rebuilt = (; rebuilt..., site_soil_layers=provenance)
    saveInfo(rebuilt, rebuilt.helpers.run.save_info)
    @info "Site soil layers" site source depth_m=depth effective_depth_m=effective layers_mm=layers
    return rebuilt
end
