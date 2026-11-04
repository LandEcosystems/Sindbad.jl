export evaporation_sigmoid

#! format: off
@bounds @describe @units @timescale @with_kw struct evaporation_sigmoid{T1,T2} <: evaporation
    beta_shape::T1 = 3.0 | (2.0, 10.0) | "sigmoid parameters" | "" | ""
    beta_50::T2 = 0.2 | (0.01, 0.5) | "sigmoid parameters" | "day-1" | "day"
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
        (sp_θ_wp, sp_θ_fc, soil_layer_thickness) ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
    end

    # multiply equilibrium PET with αSoil & [1.0 - fAPAR] to get potential soil evap
    PET_evaporation = at_least_zero(PET * (o_one - fAPAR))
    # water stress from the surface soil.
    beta_50 = clamp(beta_50, sp_θ_wp[1], sp_θ_fc[1]) # ensure beta_50 is within the range of soil moisture content
    theta = (soilW[1] + ΔsoilW[1]) / soil_layer_thickness[1] # soil moisture content, m3/m3
    beta_soil_evaporation = o_one / (o_one + exp(beta_shape * (beta_50 - theta)))
    beta_soil_evaporation = clamp_zero_one(beta_soil_evaporation)

    evaporation = PET_evaporation * beta_soil_evaporation

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

*Versions*
 - 1.0 on 04.11.2026 [jzhou]

*Created by*
 - jzhou
"""
evaporation_sigmoid
