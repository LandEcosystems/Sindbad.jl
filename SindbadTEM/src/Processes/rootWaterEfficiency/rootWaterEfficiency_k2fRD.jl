export rootWaterEfficiency_k2fRD

#! format: off
@bounds @describe @units @timescale @with_kw struct rootWaterEfficiency_k2fRD{T1,T2} <: rootWaterEfficiency
    k2_scale::T1 = 0.02 | (0.001, 0.2) | "scales vegFrac to define fraction of 2nd soil layer available for transpiration" | "" | ""
    k1_scale::T2 = 0.5 | (0.01, 0.99) | "scales vegFrac to fraction of 1st soil layer available for transpiration" | "" | ""
end
#! format: on

function define(params::rootWaterEfficiency_k2fRD, forcing, land, helpers)
    @unpack_rootWaterEfficiency_k2fRD params
    @unpack_nt soilW ⇐ land.pools

    # check if the number of soil layers and number of elements in soil thickness arrays are the same & are equal to 2 
    if length(soilW) != 2
        @warn "rootWaterEfficiency_k2fRD approach is conceptualized/designed for 2 soil layers only, but model has $(length(soilW)) layers. This approach will just update the first two layers of root water efficiency. Please check your model structure."
    end
    # create the arrays to fill in the soil properties 
    root_water_efficiency = one.(soilW)

    ## pack land variables
    @pack_nt root_water_efficiency ⇒ land.diagnostics
    return land
end

function compute(params::rootWaterEfficiency_k2fRD, forcing, land, helpers)
    ## unpack parameters
    @unpack_rootWaterEfficiency_k2fRD params

    ## unpack land variables
    @unpack_nt begin
        root_water_efficiency ⇐ land.diagnostics
        frac_vegetation ⇐ land.states
    end

    ## calculate variables
    k1_root_water_efficiency = frac_vegetation * k1_scale # the fraction of water that a root can uptake from the 1st soil layer
    k2_root_water_efficiency = frac_vegetation * k2_scale # the fraction of water that a root can uptake from the 1st soil layer
    # set the properties
    # 1st Layer
    @rep_elem k1_root_water_efficiency ⇒ (root_water_efficiency, 1, :soilW)
    # 2nd Layer
    @rep_elem k2_root_water_efficiency ⇒ (root_water_efficiency, 2, :soilW)

    ## pack land variables
    @pack_nt root_water_efficiency ⇒ land.diagnostics
    return land
end

purpose(::Type{rootWaterEfficiency_k2fRD}) = "Water uptake efficiency by roots set as a function of vegetation fraction, and for the second soil layer, as a function of rooting depth from different datasets."

@doc """

$(getModelDocString(rootWaterEfficiency_k2fRD))

---

# Extended help

*References*

*Versions*
 - 1.0 on 10.02.2020  

*Created by*
 - ttraut
"""
rootWaterEfficiency_k2fRD
