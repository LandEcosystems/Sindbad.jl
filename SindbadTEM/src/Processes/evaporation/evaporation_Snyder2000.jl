export evaporation_Snyder2000

#! format: off
@bounds @describe @units @timescale @with_kw struct evaporation_Snyder2000{T1,T2} <: evaporation
    α::T1 = 1.0 | (0.5, 1.5) | "scaling factor for PET to account for maximum bare soil evaporation" | "" | ""
    β::T2 = 3.0 | (1.0, 5.0) | "soil moisture resistance factor for soil evapotranspiration" | "mm^0.5" | ""
end
#! format: on
function define(params::evaporation_Snyder2000, forcing, land, helpers)
    ## unpack parameters
    @unpack_evaporation_Snyder2000 params

    ## unpack land variables
    @unpack_nt z_zero ⇐ land.constants

    sPET_prev = z_zero

    ## pack land variables
    @pack_nt begin
        sPET_prev ⇒ land.fluxes
    end
    return land
end

function compute(params::evaporation_Snyder2000, forcing, land, helpers)
    #@needscheck
    ## unpack parameters
    @unpack_evaporation_Snyder2000 params

    ## unpack land variables
    @unpack_nt begin
        fAPAR ⇐ land.states
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        PET ⇐ land.fluxes
        sPET_prev ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
    end
    # set the PET and ET values as precomputation; because they are needed in the first time step & updated every time
    PET = PET * α * (o_one - fAPAR)
    PET = at_least_zero(PET)

    sET = z_zero
    # get the soil moisture available PET scaled by α & a proxy of vegetation cover
    soilWAvail = soilW[1] + ΔsoilW[1]

    β2 = β * β
    isdry = soilWAvail < PET # assume wetting occurs with precip-interception > pet_soil; Snyder argued o_one should use precip > 3*pet_soil but then it becomes inconsistent here
    sPET = isdry * (sPET_prev + PET)
    issat = sPET > β2 # same as sqrt(sPET) > β (see paper); issat is a flag for stage 2 evap (name "issat" not correct here)
    ET = isdry * (!issat * sPET + issat * sqrt(sPET) * β - sET) + !isdry * PET

    # correct for conditions with light rainfall which were considered not as a wetting event; for these conditions we assume soil_evap = min(precip-ECanop, pet_soil-evap soil already used)
    ET2 = min(soilWAvail, PET - ET)
    ETsoil = ET + ET2
    evaporation = min(ETsoil, soilWAvail)

    # update soil moisture changes
    @add_to_elem -evaporation ⇒ (ΔsoilW, 1)

    # storing the ET & PET of the current time step
    sPET_prev = sPET
    sET = isdry * (sET + ET)

    ## pack land variables
    @pack_nt begin
        (sET, sPET_prev) ⇒ land.fluxes
        evaporation ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end


purpose(::Type{evaporation_Snyder2000}) = "Bare soil evaporation using the relative drying rate of soil following Snyder (2000)."

@doc """

$(getModelDocString(evaporation_Snyder2000))

---

# Extended help

*References*
 - Snyder, R. L., Bali, K., Ventura, F., & Gomez-MacPherson, H. (2000).  Estimating evaporation from bare - nearly bare soil. Journal of irrigation & drainage engineering, 126[6], 399-403.

*Versions*
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]: transfer from to accommodate land.states.fAPAR  

*Created by*
 - mjung
 - skoirala | @dr-ko
"""
evaporation_Snyder2000
