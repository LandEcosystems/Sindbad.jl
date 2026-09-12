export runoffSaturationExcess_Bergstroem1992VegFractionPFT

#! format: off
@bounds @describe @units @timescale @with_kw struct runoffSaturationExcess_Bergstroem1992VegFractionPFT{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15,T16,T17,T18,T19} <: runoffSaturationExcess
    β_Evergreen_Needleleaf_Forests::T1 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Evergreen_Needleleaf_Forests to get the berg parameter from vegFrac" | "" | ""
    β_Evergreen_Broadleaf_Forests::T2 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Evergreen_Broadleaf_Forests to get the berg parameter from vegFrac" | "" | ""
    β_Deciduous_Needleleaf_Forests::T3 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Deciduous_Needleleaf_Forests to get the berg parameter from vegFrac" | "" | ""
    β_Deciduous_Broadleaf_Forests::T4 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Deciduous_Broadleaf_Forests to get the berg parameter from vegFrac" | "" | ""
    β_Mixed_Forests::T5 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Mixed_Forests to get the berg parameter from vegFrac" | "" | ""
    β_Closed_Shrublands::T6 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Closed_Shrublands to get the berg parameter from vegFrac" | "" | ""
    β_Open_Shrublands::T7 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Open_Shrublands to get the berg parameter from vegFrac" | "" | ""
    β_Woody_Savannas::T8 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Woody_Savannas to get the berg parameter from vegFrac" | "" | ""
    β_Savannas::T9 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Savannas to get the berg parameter from vegFrac" | "" | ""
    β_Grasslands::T10 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Grasslands to get the berg parameter from vegFrac" | "" | ""
    β_Permanent_Wetlands::T11 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Permanent_Wetlands to get the berg parameter from vegFrac" | "" | ""
    β_Croplands::T12 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Croplands to get the berg parameter from vegFrac" | "" | ""
    β_Urban_and_Built_up_Lands::T13 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Urban_and_Built_up_Lands to get the berg parameter from vegFrac" | "" | ""
    β_Cropland_Natural_Vegetation_Mosaics::T14 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Cropland_Natural_Vegetation_Mosaics to get the berg parameter from vegFrac" | "" | ""
    β_Permanent_Snow_and_Ice::T15 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Permanent_Snow_and_Ice to get the berg parameter from vegFrac" | "" | ""
    β_Barren::T16 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Barren to get the berg parameter from vegFrac" | "" | ""
    β_Water_Bodies::T17 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Water_Bodies to get the berg parameter from vegFrac" | "" | ""
    β_Unclassified::T18 = 3.0 | (0.1, 5.0) | "linear scaling parameter of Unclassified to get the berg parameter from vegFrac" | "" | ""
    β_min::T19 = 0.1 | (0.08, 0.120) | "minimum effective β" | "" | ""
end
#! format: on

function precompute(params::runoffSaturationExcess_Bergstroem1992VegFractionPFT, forcing, land, helpers)
    ## unpack parameters and forcing
    #@needscheck
    @unpack_runoffSaturationExcess_Bergstroem1992VegFractionPFT params
    @unpack_nt veg_type_name ⇐ land.states

    # get the vegetation-type data & assign parameters, by canonical
    # vegetation-type name (VegTypeCatalog_SINDBAD) rather than a raw numeric
    # code tied to one specific classification
    β_PFTs = (;
        Evergreen_Needleleaf_Forests = β_Evergreen_Needleleaf_Forests,
        Evergreen_Broadleaf_Forests = β_Evergreen_Broadleaf_Forests,
        Deciduous_Needleleaf_Forests = β_Deciduous_Needleleaf_Forests,
        Deciduous_Broadleaf_Forests = β_Deciduous_Broadleaf_Forests,
        Mixed_Forests = β_Mixed_Forests,
        Closed_Shrublands = β_Closed_Shrublands,
        Open_Shrublands = β_Open_Shrublands,
        Woody_Savannas = β_Woody_Savannas,
        Savannas = β_Savannas,
        Grasslands = β_Grasslands,
        Permanent_Wetlands = β_Permanent_Wetlands,
        Croplands = β_Croplands,
        Urban_and_Built_up_Lands = β_Urban_and_Built_up_Lands,
        Cropland_Natural_Vegetation_Mosaics = β_Cropland_Natural_Vegetation_Mosaics,
        Permanent_Snow_and_Ice = β_Permanent_Snow_and_Ice,
        Barren = β_Barren,
        Water_Bodies = β_Water_Bodies,
        Unclassified = β_Unclassified,
    )
    β_veg = getproperty(β_PFTs, veg_type_name)

    # get the berg parameters according the vegetation fraction
    β_veg_max = max(β_min, β_veg)

    ## pack land variables
    @pack_nt begin
        β_veg_max ⇒ land.runoffSaturationExcess
    end
    return land
end

function compute(params::runoffSaturationExcess_Bergstroem1992VegFractionPFT, forcing, land, helpers)
    ## unpack parameters and forcing
    #@needscheck
    @unpack_runoffSaturationExcess_Bergstroem1992VegFractionPFT params

    ## unpack land variables
    @unpack_nt begin
        (WBP, frac_vegetation) ⇐ land.states
        β_veg_max ⇐ land.runoffSaturationExcess
        w_sat ⇐ land.properties
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
    end
    β_veg = β_veg_max * frac_vegetation
    # get the PFT data & assign parameters

    tmp_smax_veg = sum(w_sat)
    tmp_soilW_total = sum(soilW + ΔsoilW)

    # calculate land runoff from incoming water & current soil moisture
    tmp_sat_exc_frac = at_most_one((tmp_soilW_total / tmp_smax_veg)^β_veg)
    sat_excess_runoff = WBP * tmp_sat_exc_frac
    # update water balance pool
    WBP = WBP - sat_excess_runoff

    ## pack land variables
    @pack_nt begin
        sat_excess_runoff ⇒ land.fluxes
        β_veg ⇒ land.runoffSaturationExcess
        WBP ⇒ land.states
    end
    return land
end

purpose(::Type{runoffSaturationExcess_Bergstroem1992VegFractionPFT}) = "Saturation excess runoff using the Bergström method with parameters scaled by vegetation fraction separated by different PFTs."

@doc """

$(getModelDocString(runoffSaturationExcess_Bergstroem1992VegFractionPFT))

---

# Extended help

Each canonical vegetation-type name (`VegTypeCatalog_SINDBAD`) gets its own bounded,
independently optimizable `β_<name>` scaling parameter, selected in
`precompute` by `land.states.veg_type_name` directly rather than by a raw numeric code
plus a `+1` offset into an array. All 18 defaults are identical (3.0, the
original uniform default), so re-keying by canonical name changes no model
behavior.

These 18 fields are independently optimizable calibration parameters, not fixed
data, so unlike the four downstream tables in `ParamsForVegClasses.jl` they are not
re-keyed generically via `vegTypeCatalogFor` for other classifications: averaging two
independently calibrated bounded parameters into a group's value would silently
discard calibration signal. This approach therefore only makes sense selected
alongside a fine-grained `vegClassMap` approach (one whose target classification is
`VegTypeCatalog_SINDBAD`, i.e. no `_PlantForm` suffix) -- `land.states.veg_type_name` must
be one of the 18 `β_<name>` field names for `getproperty(β_PFTs, veg_type_name)` to resolve.

*References*
 - Bergström, S. (1992). The HBV model–its structure & applications. SMHI.

*Versions*
 - 1.0 on 10.09.2021 [ttraut]: based on runoffSaturation_BergstroemLinVegFr
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code
 - 1.1 on 27.11.2019 [skoirala | @dr-ko]: changed to handle any number of soil layers
 - 1.2 on 10.02.2020 [ttraut]: modyfying variable name to match the new SINDBAD version
 - 2.0 on 10.09.2026 [skoirala]: the 12 β_PFT0..β_PFT11 fields (keyed to raw
   MODIS PFT/Bonan codes 0-11) replaced by 18 β_<name> fields keyed to the
   canonical PFT vocabulary (PFTCatalog_SINDBAD_PFT), looked up by name instead
   of `Int(PFT) + 1`
 - 3.0 on 10.09.2026 [skoirala]: looked up by `land.states.veg_type_name` instead of
   `land.states.PFT`, following the merge of the `PFT`/`plantForm` processes
   into `vegClassMap`; field names and defaults unchanged

*Created by*
 - ttraut
"""
runoffSaturationExcess_Bergstroem1992VegFractionPFT
