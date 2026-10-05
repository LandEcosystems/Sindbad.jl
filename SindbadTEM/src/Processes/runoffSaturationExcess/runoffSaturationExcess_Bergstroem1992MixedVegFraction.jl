export runoffSaturationExcess_Bergstroem1992MixedVegFraction

#! format: off
@bounds @describe @units @timescale @with_kw struct runoffSaturationExcess_Bergstroem1992MixedVegFraction{T1,T2,T3} <: runoffSaturationExcess
    β_veg::T1 = 5.0 | (0.1, 20.0) | "linear scaling parameter for berg for vegetated fraction" | "" | ""
    β_soil::T2 = 2.0 | (0.1, 20.0) | "linear scaling parameter for berg for non vegetated fraction" | "" | ""
    β_min::T3 = 0.1 | (0.08, 0.120) | "minimum effective β" | "" | ""
end
#! format: on

function compute(params::runoffSaturationExcess_Bergstroem1992MixedVegFraction, forcing, land, helpers)
    ## unpack parameters
    @unpack_runoffSaturationExcess_Bergstroem1992MixedVegFraction params

    ## unpack land variables
    @unpack_nt begin
        (WBP, frac_vegetation) ⇐ land.states
        w_sat ⇐ land.properties
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
    end
    tmp_smax_veg = sum(w_sat)
    tmp_soilW_total = sum(soilW + ΔsoilW)

    # get the berg parameters according the vegetation fraction
    β_veg = β_veg * frac_vegetation + β_soil * (one(frac_vegetation) - frac_vegetation)
    β_veg = max(β_min, β_veg) # do this?

    # calculate land runoff from incoming water & current soil moisture
    tmp_sat_exc_frac = clamp_zero_one((tmp_soilW_total / tmp_smax_veg)^β_veg)
    sat_excess_runoff = WBP * tmp_sat_exc_frac

    # update water balance
    WBP = WBP - sat_excess_runoff

    ## pack land variables
    @pack_nt begin
        sat_excess_runoff ⇒ land.fluxes
        WBP ⇒ land.states
    end
    return land
end

purpose(::Type{runoffSaturationExcess_Bergstroem1992MixedVegFraction}) = "Saturation excess runoff using the Bergström method with separate parameters for vegetated and non-vegetated fractions."

@doc """

$(getModelDocString(runoffSaturationExcess_Bergstroem1992MixedVegFraction))

---

# Extended help

*References*
 - Bergström, S. (1992). The HBV model–its structure & applications. SMHI.

*Versions*
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code  

*Created by*
 - 1.1 on 27.11.2019: skoirala: changed to handle any number of soil layers
 - ttraut
"""
runoffSaturationExcess_Bergstroem1992MixedVegFraction
