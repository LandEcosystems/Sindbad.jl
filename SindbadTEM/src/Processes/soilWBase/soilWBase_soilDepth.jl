export soilWBase_soilDepth

struct soilWBase_soilDepth <: soilWBase end

function define(params::soilWBase_soilDepth, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        soilW ⇐ land.pools
    end

    # instatiate variables
    soil_layer_thickness = zero(soilW)
    w_fc = zero(soilW)
    w_wp = zero(soilW)
    w_sat = zero(soilW)
    w_awc = zero(soilW)
    # save the sums of selected variables
    ∑w_fc = sum(w_fc)
    ∑w_wp = sum(w_wp)
    ∑w_sat = sum(w_sat)
    ∑w_awc = sum(w_awc)

    k_sat = zero(soilW)
    k_fc = zero(soilW)
    k_wp = zero(soilW)
    ψ_sat = zero(soilW)
    ψ_fc = zero(soilW)
    ψ_wp = zero(soilW)
    θ_sat = zero(soilW)
    θ_fc = zero(soilW)
    θ_wp = zero(soilW)
    soil_α = zero(soilW)
    soil_β = zero(soilW)
    cumulative_soil_depths = cumsum(soil_layer_thickness)

    # total soil depth of the location and the deepest layer within it
    soil_depth = zero(eltype(soilW))
    idx_soilW_end = lastindex(soilW)

    @pack_nt begin
        (idx_soilW_end, soil_depth) ⇒ land.properties
        (cumulative_soil_depths, k_fc, k_sat, k_wp, soil_layer_thickness, w_awc, w_fc, w_sat, w_wp, ∑w_awc, ∑w_fc, ∑w_sat, ∑w_wp, soil_α, soil_β, θ_fc, θ_sat, θ_wp, ψ_fc, ψ_sat, ψ_wp) ⇒ land.properties
    end
    return land
end

function precompute(params::soilWBase_soilDepth, forcing, land, helpers)
    ## unpack forcing and land variables
    @unpack_nt begin
        f_soil_depth ⇐ forcing
        (sp_k_fc, sp_k_sat, sp_k_wp, sp_α, sp_β, sp_θ_fc, sp_θ_sat, sp_θ_wp, sp_ψ_fc, sp_ψ_sat, sp_ψ_wp) ⇐ land.properties
        (k_fc, k_sat, k_wp, soil_layer_thickness, w_awc, w_fc, w_sat, w_wp, ∑w_awc, ∑w_fc, ∑w_sat, ∑w_wp, soil_α, soil_β, θ_fc, θ_sat, θ_wp, ψ_fc, ψ_sat, ψ_wp) ⇐ land.properties
        idx_soilW_end ⇐ land.properties
        soilW ⇐ land.pools
        soil_depths = soilW ⇐ helpers.pools.layer_thickness
        tolerance ⇐ helpers.numbers
    end

    # soil depth of the location in mm. the forcing may hold it as a scalar or
    # as a single element array.
    depth_in = f_soil_depth isa AbstractArray ? first(f_soil_depth) : f_soil_depth
    column_depth = sum(soil_depths)
    if !(isfinite(depth_in) && depth_in > zero(depth_in))
        error("soilWBase_soilDepth: invalid f_soil_depth = $(depth_in) mm. Soil depth must be finite and positive.")
    end
    if depth_in > column_depth * (one(column_depth) + tolerance)
        error("soilWBase_soilDepth: f_soil_depth = $(depth_in) mm is deeper than the soil column of $(column_depth) mm set in pools.water.components.soilW of model_structure.json.")
    end
    soil_depth = convert(eltype(soil_layer_thickness), min(depth_in, column_depth))
    z_zero_sd = zero(soil_depth)

    layer_top = z_zero_sd
    for sl ∈ eachindex(soilW)
        # thickness of the layer within the soil depth. layers fully above the
        # soil depth keep their thickness, the layer holding it is cut at the
        # depth, and layers below it get zero thickness.
        sd_sl = clamp(soil_depth - layer_top, z_zero_sd, convert(typeof(soil_depth), soil_depths[sl]))
        layer_top = layer_top + convert(typeof(soil_depth), soil_depths[sl])
        is_active = sd_sl > z_zero_sd
        if is_active
            idx_soilW_end = sl
        end

        # conductivities are zero in inactive layers so that no water moves into
        # or out of them
        k_sat_sl = is_active ? sp_k_sat[sl] : zero(eltype(k_sat))
        k_fc_sl = is_active ? sp_k_fc[sl] : zero(eltype(k_fc))
        k_wp_sl = is_active ? sp_k_wp[sl] : zero(eltype(k_wp))
        @rep_elem k_sat_sl ⇒ (k_sat, sl)
        @rep_elem k_fc_sl ⇒ (k_fc, sl)
        @rep_elem k_wp_sl ⇒ (k_wp, sl)
        @rep_elem sp_ψ_sat[sl] ⇒ (ψ_sat, sl)
        @rep_elem sp_ψ_fc[sl] ⇒ (ψ_fc, sl)
        @rep_elem sp_ψ_wp[sl] ⇒ (ψ_wp, sl)
        @rep_elem sp_θ_sat[sl] ⇒ (θ_sat, sl)
        @rep_elem sp_θ_fc[sl] ⇒ (θ_fc, sl)
        @rep_elem sp_θ_wp[sl] ⇒ (θ_wp, sl)
        @rep_elem sp_α[sl] ⇒ (soil_α, sl)
        @rep_elem sp_β[sl] ⇒ (soil_β, sl)

        # storage capacities scale with the thickness within the soil depth
        @rep_elem sd_sl ⇒ (soil_layer_thickness, sl)
        p_w_fc_sl = θ_fc[sl] * sd_sl
        @rep_elem p_w_fc_sl ⇒ (w_fc, sl)
        w_wp_sl = θ_wp[sl] * sd_sl
        @rep_elem w_wp_sl ⇒ (w_wp, sl)
        p_w_sat_sl = θ_sat[sl] * sd_sl
        @rep_elem p_w_sat_sl ⇒ (w_sat, sl)

        # remove initial water that does not fit in the layer, which empties
        # the inactive layers
        soilW_sl = min(soilW[sl], w_sat[sl])
        @rep_elem soilW_sl ⇒ (soilW, sl)
    end

    # depth of the bottom of each layer
    cumulative_soil_depths = cumsum(soil_layer_thickness)

    # get the plant available water capacity
    w_awc = w_fc - w_wp

    # save the sums of selected variables
    ∑w_fc = sum(w_fc)
    ∑w_wp = sum(w_wp)
    ∑w_sat = sum(w_sat)
    ∑w_awc = sum(w_awc)

    @pack_nt begin
        (idx_soilW_end, soil_depth) ⇒ land.properties
        (cumulative_soil_depths, k_fc, k_sat, k_wp, soil_layer_thickness, w_awc, w_fc, w_sat, w_wp, ∑w_awc, ∑w_fc, ∑w_sat, ∑w_wp, soil_α, soil_β, θ_fc, θ_sat, θ_wp, ψ_fc, ψ_sat, ψ_wp) ⇒ land.properties
        soilW ⇒ land.pools
    end
    return land
end

purpose(::Type{soilWBase_soilDepth}) = "Soil hydraulic properties for different soil layers assuming a uniform vertical distribution, with the soil column truncated at the soil depth from forcing."

@doc """

$(getModelDocString(soilWBase_soilDepth))

---

# Extended help

The soil layers from pools.water.components.soilW in model_structure.json are cut
at the soil depth given by the forcing variable f_soil_depth in mm. Layers above
the soil depth keep their thickness. The layer that holds the soil depth gets the
thickness between its top and the soil depth, so its storage capacities scale with
that thickness. Layers below the soil depth get zero thickness, storage capacity
and conductivity, and their initial water is removed. The number of layers stays
the same for all locations.

The index of the deepest layer with non-zero thickness is saved as
idx_soilW_end. Drainage, capillary flow and the exchange with groundwater use
it as the bottom of the soil column.

f_soil_depth must be finite, positive and not deeper than the total thickness of
the soil layers, otherwise an error is thrown.

*References*

*Versions*
 - 1.0 on 05.10.2026 [skoirala | @dr-ko]: based on soilWBase_uniform, with soil
   depth from forcing

*Created by*
 - skoirala | @dr-ko
"""
soilWBase_soilDepth
