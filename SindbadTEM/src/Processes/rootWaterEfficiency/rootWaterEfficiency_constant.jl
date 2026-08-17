export rootWaterEfficiency_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct rootWaterEfficiency_constant{T1} <: rootWaterEfficiency
    constant_root_water_efficiency::T1 = 0.99 | (0.001, 0.999) | "root fraction" | "" | ""
end
#! format: on

function define(params::rootWaterEfficiency_constant, forcing, land, helpers)
    @unpack_rootWaterEfficiency_constant params
    
    @unpack_nt begin
        soil_layer_thickness ⇐ land.properties
        soilW ⇐ land.pools            
    end

    cumulative_soil_depths = cumsum(soil_layer_thickness)
    ## Instantiate
    root_water_efficiency = one.(soilW)

    ## pack land variables
    @pack_nt begin
        root_water_efficiency ⇒ land.diagnostics
        cumulative_soil_depths ⇒ land.properties
    end

    return land
end


function precompute(params::rootWaterEfficiency_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_rootWaterEfficiency_constant params
    ## unpack land variables
    @unpack_nt begin
        cumulative_soil_depths ⇐ land.properties
        root_water_efficiency ⇐ land.diagnostics
        soilW ⇐ land.pools
        z_zero ⇐ land.constants
        max_root_depth ⇐ land.diagnostics
    end
    @rep_elem ifelse(max_root_depth >= z_zero, constant_root_water_efficiency, root_water_efficiency[1]) ⇒ (root_water_efficiency, 1, :soilW)
    for sl ∈ eachindex(soilW)[2:end]
        soilcumuD = cumulative_soil_depths[sl-1]
        rootOver = max_root_depth - soilcumuD
        rootEff = ifelse(rootOver >= z_zero, constant_root_water_efficiency, zero(eltype(root_water_efficiency)))
        @rep_elem rootEff ⇒ (root_water_efficiency, sl, :soilW)
    end
    ## pack land variables
    @pack_nt root_water_efficiency ⇒ land.diagnostics
    return land
end

purpose(::Type{rootWaterEfficiency_constant}) = "Water uptake efficiency by roots set as a constant for each soil layer."

@doc """

$(getModelDocString(rootWaterEfficiency_constant))

---

# Extended help

*References*

*Versions*
 - 1.0 on 21.11.2019  

*Created by*
 - skoirala | @dr-ko
"""
rootWaterEfficiency_constant
