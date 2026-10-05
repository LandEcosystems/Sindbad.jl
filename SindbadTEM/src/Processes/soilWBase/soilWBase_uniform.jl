export soilWBase_uniform

struct soilWBase_uniform <: soilWBase end

function define(params::soilWBase_uniform, forcing, land, helpers)
    #@needscheck
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

    # get the plant available water capacity

    @pack_nt begin
        (k_fc, k_sat, k_wp, soil_layer_thickness, w_awc, w_fc, w_sat, w_wp, ∑w_awc, ∑w_fc, ∑w_sat, ∑w_wp, soil_α, soil_β, θ_fc, θ_sat, θ_wp, ψ_fc, ψ_sat, ψ_wp) ⇒ land.properties
    end
    return land
end

function precompute(params::soilWBase_uniform, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        (sp_k_fc, sp_k_sat, sp_k_wp, sp_α, sp_β, sp_θ_fc, sp_θ_sat, sp_θ_wp, sp_ψ_fc, sp_ψ_sat, sp_ψ_wp) ⇐ land.properties
        (k_fc, k_sat, k_wp, soil_layer_thickness, w_awc, w_fc, w_sat, w_wp, ∑w_awc, ∑w_fc, ∑w_sat, ∑w_wp, soil_α, soil_β, θ_fc, θ_sat, θ_wp, ψ_fc, ψ_sat, ψ_wp) ⇐ land.properties
        soilW ⇐ land.pools
        soil_depths = soilW ⇐ helpers.pools.layer_thickness 
    end

    for sl ∈ eachindex(soilW)
        @rep_elem sp_k_sat[sl] ⇒ (k_sat, sl)
        @rep_elem sp_k_fc[sl] ⇒ (k_fc, sl)
        @rep_elem sp_k_wp[sl] ⇒ (k_wp, sl)
        @rep_elem sp_ψ_sat[sl] ⇒ (ψ_sat, sl)
        @rep_elem sp_ψ_fc[sl] ⇒ (ψ_fc, sl)
        @rep_elem sp_ψ_wp[sl] ⇒ (ψ_wp, sl)
        @rep_elem sp_θ_sat[sl] ⇒ (θ_sat, sl)
        @rep_elem sp_θ_fc[sl] ⇒ (θ_fc, sl)
        @rep_elem sp_θ_wp[sl] ⇒ (θ_wp, sl)
        @rep_elem sp_α[sl] ⇒ (soil_α, sl)
        @rep_elem sp_β[sl] ⇒ (soil_β, sl)

        sd_sl = soil_depths[sl]
        @rep_elem sd_sl ⇒ (soil_layer_thickness, sl)
        p_w_fc_sl = θ_fc[sl] * sd_sl
        @rep_elem p_w_fc_sl ⇒ (w_fc, sl)
        w_wp_sl = θ_wp[sl] * sd_sl
        @rep_elem w_wp_sl ⇒ (w_wp, sl)
        p_w_sat_sl = θ_sat[sl] * sd_sl
        @rep_elem p_w_sat_sl ⇒ (w_sat, sl)
        # soilW_sl = min(soilW[sl], w_sat[sl])
        # @rep_elem soilW_sl ⇒ (soilW, sl)
    end

    # get the plant available water capacity
    w_awc = w_fc - w_wp

    # save the sums of selected variables
    ∑w_fc = sum(w_fc)
    ∑w_wp = sum(w_wp)
    ∑w_sat = sum(w_sat)
    ∑w_awc = sum(w_awc)

    @pack_nt begin
        (k_fc, k_sat, k_wp, soil_layer_thickness, w_awc, w_fc, w_sat, w_wp, ∑w_awc, ∑w_fc, ∑w_sat, ∑w_wp, soil_α, soil_β, θ_fc, θ_sat, θ_wp, ψ_fc, ψ_sat, ψ_wp) ⇒ land.properties
        soilW ⇒ land.pools
    end
    return land
end

purpose(::Type{soilWBase_uniform}) = "Soil hydraulic properties distributed for different soil layers assuming a uniform vertical distribution."

@doc """

$(getModelDocString(soilWBase_uniform))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.11.2019 [skoirala | @dr-ko]: clean up & consistency
 - 1.1 on 03.12.2019 [skoirala | @dr-ko]: handling potentail vertical distribution of soil texture  

*Created by*
 - ncarvalhais
 - skoirala | @dr-ko
"""
soilWBase_uniform
