export soilWBase_smax2Layer

#! format: off
@bounds @describe @units @timescale @with_kw struct soilWBase_smax2Layer{T1,T2} <: soilWBase
    smax1::T1 = 1.0 | (0.001, 1.0) | "maximum soil water holding capacity of 1st soil layer, as % of defined soil depth" | "" | ""
    smax2::T2 = 0.3 | (0.01, 1.0) | "maximum plant available water in 2nd soil layer, as % of defined soil depth" | "" | ""
end
#! format: on

function define(params::soilWBase_smax2Layer, forcing, land, helpers)
    @unpack_soilWBase_smax2Layer params

    @unpack_nt begin
        soilW ⇐ land.pools
        n_soilW = soilW ⇐ helpers.pools.n_layers
    end
    ## precomputations/check
    # get the soil thickness & root distribution information from input
    soil_layer_thickness = helpers.pools.layer_thickness.soilW
    # check if the number of soil layers and number of elements in soil thickness arrays are the same & are equal to 2 
    if n_soilW != 2
        @warn "soilWBase_smax2Layer needs exactly 2 soil layers in model_structure.json, but model has $n_soilW layers. This approach will just update the first two layers of soil water properties. Please check your model structure."
    end

    ## Instantiate variables
    w_sat = zero(soilW)
    w_fc = zero(soilW)
    w_wp = zero(soilW)

    ## pack land variables
    @pack_nt (soil_layer_thickness, w_sat, w_fc, w_wp) ⇒ land.properties
    return land
end

function compute(params::soilWBase_smax2Layer, forcing, land, helpers)
    ## unpack parameters
    @unpack_soilWBase_smax2Layer params

    ## unpack land variables
    @unpack_nt (soil_layer_thickness, w_sat, w_fc, w_wp) ⇐ land.properties

    ## calculate variables
    # set the properties for each soil layer
    # 1st layer
    @rep_elem smax1 * soil_layer_thickness[1] ⇒ (w_sat, 1, :soilW)
    @rep_elem smax2 * soil_layer_thickness[2] ⇒ (w_sat, 2, :soilW)
    @rep_elem smax1 * soil_layer_thickness[1] ⇒ (w_fc, 1, :soilW)
    @rep_elem smax2 * soil_layer_thickness[2] ⇒ (w_fc, 2, :soilW)

    # get the plant available water available (all the water is plant available)
    w_awc = w_sat

    ## pack land variables
    @pack_nt (w_awc, w_fc, w_sat, w_wp, soil_layer_thickness) ⇒ land.properties
    return land
end

purpose(::Type{soilWBase_smax2Layer}) = "Maximum soil water content of two soil layers as fractions of total soil depth, based on the older version of the Pre-Tokyo Model."

@doc """

$(getModelDocString(soilWBase_smax2Layer))

---

# Extended help

*References*

*Versions*
 - 1.0 on 09.01.2020 [ttraut]: clean up & consistency  

*Created by*
 - ttraut
"""
soilWBase_smax2Layer
