export rootSurfaceArea

abstract type rootSurfaceArea <: LandEcosystem end

include("rootSurfaceArea_Biomass.jl")
include("rootSurfaceArea_vom.jl")

@doc """
Root surface area

# Approaches:
 - Biomass: rootSurfaceArea from each soil layer is a function of the root biomass in the layer and PFT-specific parameters
 - vom: rootSurfaceArea from each soil layer is calculated based on VOM methodology
"""
rootSurfaceArea
