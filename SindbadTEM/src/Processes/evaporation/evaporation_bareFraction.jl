export evaporation_bareFraction

#! format: off
@bounds @describe @units @timescale @with_kw struct evaporation_bareFraction{T1} <: evaporation
    ks::T1 = 0.5 | (0.1, 0.95) | "resistance against soil evaporation" | "" | ""
end
#! format: on

function compute(params::evaporation_bareFraction, forcing, land, helpers)
    ## unpack parameters
    @unpack_evaporation_bareFraction params

    ## unpack land variables
    @unpack_nt begin
        frac_vegetation ⇐ land.states
        ΔsoilW ⇐ land.pools
        soilW ⇐ land.pools
        PET ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
    end
    # scale the potential ET with bare soil fraction
    PET_evaporation = PET * (o_one - frac_vegetation)
    # calculate actual ET as a fraction of PET_evaporation
    evaporation = min(PET_evaporation, (soilW[1] + ΔsoilW[1]) * ks)

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

purpose(::Type{evaporation_bareFraction}) = "Bare soil evaporation from the non-vegetated fraction of the grid as a linear function of soil moisture and potential evaporation."

@doc """

$(getModelDocString(evaporation_bareFraction))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]: clean up the code & moved from prec to dyna to handle land.states.frac_vegetation  

*Created by*
 - mjung
 - skoirala | @dr-ko
 - ttraut
"""
evaporation_bareFraction
