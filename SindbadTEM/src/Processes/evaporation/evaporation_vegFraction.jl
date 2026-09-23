export evaporation_vegFraction

#! format: off
@bounds @describe @units @timescale @with_kw struct evaporation_vegFraction{T1,T2} <: evaporation
    α::T1 = 1.0 | (0.0, 3.0) | "α coefficient of Priestley-Taylor formula for soil" | "" | ""
    k_evaporation::T2 = 0.2 | (0.03, 0.98) | "fraction of soil water that can be used for soil evaporation" | "day-1" | "day"
end
#! format: on

function compute(params::evaporation_vegFraction, forcing, land, helpers)
    ## unpack parameters
    @unpack_evaporation_vegFraction params

    ## unpack land variables
    @unpack_nt begin
        frac_vegetation ⇐ land.states
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        PET ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
    end

    # multiply equilibrium PET with αSoil & [1.0 - frac_vegetation] to get potential soil evap
    tmp = PET * α * (o_one - frac_vegetation)
    PET_evaporation = at_least_zero(tmp)

    # scale the potential with the a fraction of available water & get the minimum of the current moisture
    evaporation = min(PET_evaporation, k_evaporation * (soilW[1] + ΔsoilW[1]))

    # update soil moisture changes
    @add_to_elem -evaporation ⇒ (ΔsoilW, 1)

    ## pack land variables
    @pack_nt begin
        PET_evaporation ⇒ land.fluxes
        evaporation ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end

purpose(::Type{evaporation_vegFraction}) = "Bare soil evaporation from the non-vegetated fraction and potential evaporation."

@doc """

$(getModelDocString(evaporation_vegFraction))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]: clean up the code & moved from prec to dyna to handle land.states.frac_vegetation  

*Created by*
 - mjung
 - skoirala | @dr-ko
"""
evaporation_vegFraction
