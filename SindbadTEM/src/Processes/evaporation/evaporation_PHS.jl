export evaporation_PHS

#! format: off
@bounds @describe @units @timescale @with_kw struct evaporation_PHS{T1} <: evaporation
    k_evaporation::T1 = 0.2 | (0.05, 0.95) | "fraction of soil water that can be used for soil evaporation" | "day-1" | "day"
end
#! format: on

function compute(params::evaporation_PHS, forcing, land, helpers)
    @unpack_evaporation_PHS params
    ## unpack land variables
    @unpack_nt begin
        phs_evaporation ⇐ land.diagnostics
        (soilW, ΔsoilW) ⇐ land.pools
    end

    soilWAvail = k_evaporation * (soilW[1] + ΔsoilW[1])
    evaporation = min(at_least_zero(phs_evaporation), soilWAvail)

    # update soil moisture changes
    @add_to_elem -evaporation ⇒ (ΔsoilW, 1)

    ## pack land variables
    @pack_nt begin
        evaporation ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end

purpose(::Type{evaporation_PHS}) = "Calculate Es based on PM equation."

@doc """

$(getModelDocString(evaporation_PHS))

---

# Extended help

*Versions*
 - 1.0 on 11/10/2026 [jzhou] 

*Created by*
 - jzhou
"""
evaporation_PHS
