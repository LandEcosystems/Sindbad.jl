export soilWBase_smax1Layer

#! format: off
@bounds @describe @units @timescale @with_kw struct soilWBase_smax1Layer{T1} <: soilWBase
    smax::T1 = 1.0 | (0.001, 10.0) | "maximum soil water holding capacity of 1st soil layer, as % of defined soil depth" | "" | ""
end
#! format: on

function define(params::soilWBase_smax1Layer, forcing, land, helpers)
    @unpack_soilWBase_smax1Layer params

    @unpack_nt begin
        soilW ⇐ land.pools
        n_soilW = soilW ⇐ helpers.pools.n_layers
    end
    ## precomputations/check
    # get the soil thickness & root distribution information from input
    soil_layer_thickness = helpers.pools.layer_thickness.soilW
    # check if the number of soil layers and number of elements in soil thickness arrays are the same & are equal to 1 
    if n_soilW != 1
        @warn "soilWBase_smax1Layer needs exactly 1 soil layer in model_structure.json, but model has $n_soilW layers. This approach will just update the first layer of soil water properties. Please check your model structure."
    end

    ## Instantiate variables
    w_sat = zero(soilW)
    w_fc = zero(soilW)
    w_wp = zero(soilW)

    ## pack land variables
    @pack_nt (soil_layer_thickness, w_sat, w_fc, w_wp) ⇒ land.properties
    return land
end

function compute(params::soilWBase_smax1Layer, forcing, land, helpers)
    ## unpack parameters
    @unpack_soilWBase_smax1Layer params

    ## unpack land variables
    @unpack_nt (soil_layer_thickness, w_sat, w_fc, w_wp) ⇐ land.properties

    ## calculate variables

    # set the properties for each soil layer
    # 1st layer
    @rep_elem smax * soil_layer_thickness[1] ⇒ (w_sat, 1, :soilW)
    @rep_elem smax * soil_layer_thickness[1] ⇒ (w_fc, 1, :soilW)

    # get the plant available water available (all the water is plant available)
    w_awc = w_sat

    ## pack land variables
    @pack_nt (w_awc, w_fc, w_sat, w_wp) ⇒ land.properties
    return land
end

purpose(::Type{soilWBase_smax1Layer}) = "Maximum soil water content of one soil layer as a fraction of total soil depth, based on the Trautmann et al. (2018) model."

@doc """

$(getModelDocString(soilWBase_smax1Layer))

---

# Extended help

*References*
 - Trautmann et al. 2018

*Versions*
 - 1.0 on 09.01.2020 [ttraut]: clean up & consistency  

*Created by*
 - ttraut
"""
soilWBase_smax1Layer
