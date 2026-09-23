export evaporation_demandSupply

#! format: off
@bounds @describe @units @timescale @with_kw struct evaporation_demandSupply{T1,T2} <: evaporation
    α::T1 = 1.0 | (0.1, 3.0) | "α coefficient of Priestley-Taylor formula for soil" | "" | ""
    k_evaporation::T2 = 0.2 | (0.05, 0.98) | "fraction of soil water that can be used for soil evaporation" | "day-1" | "day"
end
#! format: on

function compute(params::evaporation_demandSupply, forcing, land, helpers)
    ## unpack parameters
    @unpack_evaporation_demandSupply params

    ## unpack land variables
    @unpack_nt begin
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        PET ⇐ land.fluxes
        z_zero ⇐ land.constants
    end
    # calculate potential soil evaporation
    PET_evaporation = at_least_zero(PET * α)
    evaporationSupply = at_least_zero(k_evaporation * (soilW[1] + ΔsoilW[1]))

    # calculate the soil evaporation as a fraction of scaling parameter & PET
    evaporation = min(PET_evaporation, evaporationSupply)

    # update soil moisture changes
    @add_to_elem -evaporation ⇒ (ΔsoilW, 1)
    ## pack land variables
    @pack_nt begin
        (PET_evaporation, evaporationSupply) ⇒ land.fluxes
        evaporation ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end

purpose(::Type{evaporation_demandSupply}) = "Bare soil evaporation using a demand-supply limited approach."

@doc """

$(getModelDocString(evaporation_demandSupply))

---

# Extended help

*References*
 - Teuling et al.

*Versions*
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]: clean up the code
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]: clean up the code  

*Created by*
 - mjung
 - skoirala | @dr-ko
 - ttraut

*Notes*
 - considers that the soil evaporation can occur from the whole grid & not only the  non-vegetated fraction of the grid cell  
"""
evaporation_demandSupply
