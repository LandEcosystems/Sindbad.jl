export runoffSaturationExcess_Bergstroem1992VegFractionFroSoil

#! format: off
@bounds @describe @units @timescale @with_kw struct runoffSaturationExcess_Bergstroem1992VegFractionFroSoil{T1,T2,T3} <: runoffSaturationExcess
    β::T1 = 3.0 | (0.1, 10.0) | "linear scaling parameter to get the berg parameter from vegFrac" | "" | ""
    frozen_frac_scalar::T2 = 1.0 | (0.1, 3.0) | "linear scaling parameter for frozen Soil fraction" | "" | ""
    β_min::T3 = 0.1 | (0.08, 0.120) | "minimum effective β" | "" | ""
end
#! format: on

function compute(params::runoffSaturationExcess_Bergstroem1992VegFractionFroSoil, forcing, land, helpers)
    ## unpack parameters and forcing
    #@needscheck
    @unpack_runoffSaturationExcess_Bergstroem1992VegFractionFroSoil params
    @unpack_nt frac_frozen_soil ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        (WBP, frac_vegetation) ⇐ land.states
        w_sat ⇐ land.properties
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        (z_zero, o_one) ⇐ land.constants
        tolerance ⇐ helpers.numbers
    end

    # scale the input frozen soil fraction; maximum is 1
    frac_frozen = at_most_one(frac_frozen_soil * frozen_frac_scalar)
    tmp_smax_veg = sum(w_sat) * (o_one - frac_frozen + tolerance)
    tmp_soilW_total = sum(soilW + ΔsoilW)

    # get the berg parameters according the vegetation fraction
    β_veg = max(β_min, β * frac_vegetation) # do this?

    # calculate land runoff from incoming water & current soil moisture
    tmp_sat_exc_frac = clamp_zero_one((tmp_soilW_total / tmp_smax_veg)^β_veg)
    sat_excess_runoff = WBP * tmp_sat_exc_frac

    # update water balance pool
    WBP = WBP - sat_excess_runoff

    ## pack land variables
    @pack_nt begin
        sat_excess_runoff ⇒ land.fluxes
        (frac_frozen, β_veg) ⇒ land.runoffSaturationExcess
        WBP ⇒ land.states
    end
    return land
end

purpose(::Type{runoffSaturationExcess_Bergstroem1992VegFractionFroSoil}) = "Saturation excess runoff using the Bergström method with parameters scaled by vegetation fraction and frozen soil fraction."

@doc """

$(getModelDocString(runoffSaturationExcess_Bergstroem1992VegFractionFroSoil))

---

# Extended help

*References*
 - Bergstroem, S. (1992). The HBV model–its structure & applications. SMHI.

*Versions*
 - 1.0 on 18.11.2019 [ttraut]  

*Created by*
 - ttraut
"""
runoffSaturationExcess_Bergstroem1992VegFractionFroSoil
