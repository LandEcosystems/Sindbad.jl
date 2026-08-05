export runoffSaturationExcess_satFraction

struct runoffSaturationExcess_satFraction <: runoffSaturationExcess end

function compute(params::runoffSaturationExcess_satFraction, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt (WBP, frac_saturation) ⇐ land.states

    ## calculate variables
    sat_excess_runoff = WBP * frac_saturation

    # update the WBP
    WBP = WBP - sat_excess_runoff

    ## pack land variables
    @pack_nt begin
        sat_excess_runoff ⇒ land.fluxes
        WBP ⇒ land.states
    end
    return land
end

purpose(::Type{runoffSaturationExcess_satFraction}) = "Saturation excess runoff as a fraction of the saturated fraction of a grid-cell."

@doc """

$(getModelDocString(runoffSaturationExcess_satFraction))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]: cleaned up the code  

*Created by*
 - skoirala | @dr-ko

*Notes*
 - only works if soilWSatFrac module is activated
"""
runoffSaturationExcess_satFraction
