export evaporation_fAPAR

#! format: off
@bounds @describe @units @timescale @with_kw struct evaporation_fAPAR{T1,T2} <: evaporation
    α::T1 = 1.0 | (0.1, 3.0) | "α coefficient of Priestley-Taylor formula for soil" | "" | ""
    k_evaporation::T2 = 0.2 | (0.05, 0.95) | "fraction of soil water that can be used for soil evaporation" | "day-1" | "day"
end
#! format: on

function compute(params::evaporation_fAPAR, forcing, land, helpers)
    ## unpack parameters
    @unpack_evaporation_fAPAR params

    ## unpack land variables
    @unpack_nt begin
        fAPAR ⇐ land.states
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        PET ⇐ land.fluxes
        (z_zero, o_one, t_two) ⇐ land.constants
    end
    # multiply equilibrium PET with αSoil & [1.0 - fAPAR] to get potential soil evap
    tmp = PET * α * (o_one - fAPAR)
    PET_evaporation = at_least_zero(tmp)
    # scale the potential with the a fraction of available water & get the minimum of the current moisture
    evaporation = min(PET_evaporation, k_evaporation * (soilW[1] + ΔsoilW[1]))
    # evaporation = k_evaporation * (soilW[1] + ΔsoilW[1])

    # update soil moisture changes
    @add_to_elem -evaporation ⇒ (ΔsoilW, 1, :soilW)

    ## pack land variables
    @pack_nt begin
        PET_evaporation ⇒ land.fluxes
        evaporation ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end

purpose(::Type{evaporation_fAPAR}) = "Bare soil evaporation from the non-absorbed fAPAR (as a proxy for vegetation fraction) and potential evaporation."

@doc """

$(getModelDocString(evaporation_fAPAR))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]: clean up the code & moved from prec to dyna to handle land.states.frac_vegetation  

*Created by*
 - mjung
 - skoirala | @dr-ko
"""
evaporation_fAPAR
