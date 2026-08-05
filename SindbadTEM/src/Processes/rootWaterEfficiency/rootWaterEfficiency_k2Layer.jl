export rootWaterEfficiency_k2Layer

#! format: off
@bounds @describe @units @timescale @with_kw struct rootWaterEfficiency_k2Layer{T1,T2} <: rootWaterEfficiency
    k2::T1 = 0.02 | (0.001, 0.2) | "fraction of 2nd soil layer available for transpiration" | "" | ""
    k1::T2 = 0.5 | (0.01, 0.99) | "fraction of 1st soil layer available for transpiration" | "" | ""
end
#! format: on

function define(params::rootWaterEfficiency_k2Layer, forcing, land, helpers)
    @unpack_rootWaterEfficiency_k2Layer params
    @unpack_nt soilW ⇐ land.pools

    ## precomputations/check

    # check if the number of soil layers is equal to 2
    if length(soilW) != 2
        @warn "rootWaterEfficiency_k2Layer approach is conceptualized/designed for 2 soil layers only, but model has $(length(soilW)) layers. This approach will just update the first two layers of root water efficiency. Please check your model structure."
    end
    # create the arrays to fill in the soil properties
    root_water_efficiency = one.(soilW)

    ## pack land variables
    @pack_nt root_water_efficiency ⇒ land.diagnostics
    return land
end

function compute(params::rootWaterEfficiency_k2Layer, forcing, land, helpers)
    ## unpack parameters
    @unpack_rootWaterEfficiency_k2Layer params

    ## unpack land variables
    @unpack_nt root_water_efficiency ⇐ land.diagnostics

    ## calculate variables
    k1_root_water_efficiency = k1 # the fraction of water that a root can uptake from the 1st soil layer
    k2_root_water_efficiency = k2 # the fraction of water that a root can uptake from the 1st soil layer
    # set the properties
    # 1st Layer
    @rep_elem k1_root_water_efficiency ⇒ (root_water_efficiency, 1, :soilW)
    # 2nd Layer
    @rep_elem k2_root_water_efficiency ⇒ (root_water_efficiency, 2, :soilW)


    ## pack land variables
    @pack_nt root_water_efficiency ⇒ land.diagnostics
    return land
end

purpose(::Type{rootWaterEfficiency_k2Layer}) = "Water uptake efficiency by roots set as a calibration parameter for each soil layer (for two soil layers)."

@doc """

$(getModelDocString(rootWaterEfficiency_k2Layer))

---

# Extended help

*References*

*Versions*
 - 1.0 on 09.01.2020  

*Created by*
 - ttraut
"""
rootWaterEfficiency_k2Layer
