export runoffInfiltrationExcess_Jung

struct runoffInfiltrationExcess_Jung <: runoffInfiltrationExcess end

function compute(params::runoffInfiltrationExcess_Jung, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        (WBP, fAPAR) ⇐ land.states
        k_sat ⇐ land.properties
        rain ⇐ land.fluxes
        rain_int ⇐ land.states
        (z_zero, o_one) ⇐ land.constants
    end
    # assumes infiltration capacity is unlimited in the vegetated fraction [infiltration flux = P*fpar] the infiltration flux for the unvegetated fraction is given as the minimum of the precip & the min of precip intensity [P] & infiltration capacity [I] scaled with rain duration [P/R]

    # get infiltration capacity of the first layer
    pInfCapacity = k_sat[1] #/ in mm / hr
    InfExcess =
        rain - (rain * fAPAR +
                (o_one - fAPAR) * min(rain, min(pInfCapacity, rain_int) * rain / rain_int))
    inf_excess_runoff = rain > z_zero ? InfExcess : zero(InfExcess)
    WBP = WBP - inf_excess_runoff

    ## pack land variables
    @pack_nt begin
        inf_excess_runoff ⇒ land.fluxes
        WBP ⇒ land.states
    end
    return land
end

purpose(::Type{runoffInfiltrationExcess_Jung}) = "Infiltration excess runoff as a function of rain intensity and vegetated fraction."

@doc """

$(getModelDocString(runoffInfiltrationExcess_Jung))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code
 - 1.1 on 22.11.2019 [skoirala | @dr-ko]: moved from prec to dyna to handle land.states.fAPAR which is nPix, 1  

*Created by*
 - mjung
"""
runoffInfiltrationExcess_Jung
