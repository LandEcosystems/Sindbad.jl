export evaporation_sigmoid

#! format: off
@bounds @describe @units @timescale @with_kw struct evaporation_sigmoid{T1,T2, T3} <: evaporation
    beta_shape::T1 = 10.0 | (4.0, 40.0) | "sensitivity of Es to soil moisture" | "" | ""
    beta_50::T2 = 0.4 | (0.1, 0.9) | "water stress equals 0.5. Relative soil saturation" | "" | ""
    α::T3 = 1.0 | (0.5, 1.5) | "α coefficient of Priestley-Taylor formula for soil" | "" | ""
end
#! format: on

function compute(params::evaporation_sigmoid, forcing, land, helpers)
    ## unpack parameters
    @unpack_evaporation_sigmoid params

    ## unpack land variables
    @unpack_nt begin
        fAPAR ⇐ land.states
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        PET ⇐ land.fluxes
        (f_thetar_van_Genuchten, f_thetas_van_Genuchten) ⇐ forcing
        soil_layer_thickness ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
    end

    # multiply equilibrium PET with αSoil & [1.0 - fAPAR] to get potential soil evap
    PET_evaporation = at_least_zero(PET * α * (o_one - fAPAR))
    # water stress from the surface soil.
    dz = soil_layer_thickness[1]
    θ_r, θ_s = f_thetar_van_Genuchten, f_thetas_van_Genuchten
    W_top = soilW[1] + ΔsoilW[1]
    saturation = clamp_zero_one((W_top / dz - θ_r) / (θ_s - θ_r))
    β_raw = o_one / (o_one + exp(beta_shape * (beta_50 - saturation)))
    β_dry = o_one / (o_one + exp(beta_shape * beta_50))
    β_wet = o_one / (o_one + exp(beta_shape * (beta_50 - o_one)))
    beta_soil_evaporation = clamp_zero_one((β_raw - β_dry) / (β_wet - β_dry))

    # Soil evaporation is limited by the available water in the top soil layer.
    evaporation = min(PET_evaporation * beta_soil_evaporation, at_least_zero(W_top - θ_r * dz))

    # update soil moisture changes
    @add_to_elem -evaporation ⇒ (ΔsoilW, 1)

    ## pack land variables
    @pack_nt begin
        PET_evaporation ⇒ land.fluxes
        evaporation ⇒ land.fluxes
        beta_soil_evaporation ⇒ land.diagnostics
        ΔsoilW ⇒ land.pools
    end
    return land
end

purpose(::Type{evaporation_sigmoid}) = "Bare soil evaporation from potential evaporation and water stress."

@doc """

$(getModelDocString(evaporation_sigmoid))

---

# Extended help

*References*
1. Lee, T. J., & Pielke, R. A. (1992). Estimating the soil surface specific humidity. Journal of Applied Meteorology, 31(5), 480–484.
2. Merlin, O., Al Bitar, A., Rivalland, V., Béziat, P., Ceschia, E., & Dedieu, G. (2011). An analytical model of evaporation efficiency for unsaturated soil surfaces with an arbitrary thickness. Journal of Applied Meteorology and Climatology, 50(2), 457–471. doi:10.1175/2010JAMC2418.1

*Versions*
 - 1.0 on 04.11.2026 [jzhou]

*Created by*
 - jzhou
"""
evaporation_sigmoid
