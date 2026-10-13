export runoffSaturationExcess_Bergstroem1992

#! format: off
@bounds @describe @units @timescale @with_kw struct runoffSaturationExcess_Bergstroem1992{T1} <: runoffSaturationExcess
    β::T1 = 1.1 | (0.1, 5.0) | "berg exponential parameter" | "" | ""
end
#! format: on

function compute(params::runoffSaturationExcess_Bergstroem1992, forcing, land, helpers)
    ## unpack parameters
    @unpack_runoffSaturationExcess_Bergstroem1992 params

    ## unpack land variables
    @unpack_nt begin
        WBP ⇐ land.states
        w_sat ⇐ land.properties
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
    end
    # @show WBP
    tmp_smax_veg = sum(w_sat)
    tmp_soilW_total = sum(soilW)
    # calculate land runoff from incoming water & current soil moisture
    # tmp_sat_exc_frac = clamp_zero_one((tmp_soilW_total / tmp_smax_veg)^β)
    tmp_sat_exc_frac = clamp_zero_one((at_least_zero(tmp_soilW_total) / tmp_smax_veg)^β)

    sat_excess_runoff = WBP * tmp_sat_exc_frac

    # update water balance pool
    WBP = WBP - sat_excess_runoff

    ## pack land variables
    @pack_nt begin
        sat_excess_runoff ⇒ land.fluxes
        WBP ⇒ land.states
    end
    return land
end

purpose(::Type{runoffSaturationExcess_Bergstroem1992}) = "Saturation excess runoff using the original Bergström method."

@doc """

$(getModelDocString(runoffSaturationExcess_Bergstroem1992))

---

# Extended help

*References*
 - Bergström, S. (1992). The HBV model–its structure & applications. SMHI.

*Versions*
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code  
 - 1.1 on 27.11.2019 [skoirala | @dr-ko]: changed to handle any number of soil layers
 - 1.2 on 10.02.2020 [ttraut]: modyfying variable name to match the new SINDBAD version

*Created by*
 - ttraut
"""
runoffSaturationExcess_Bergstroem1992
