export cFlowSoilProperties

abstract type cFlowSoilProperties <: LandEcosystem end

purpose(::Type{cFlowSoilProperties}) = "Effect of soil properties on carbon transfers between pools."

includeApproaches(cFlowSoilProperties, @__DIR__)

@doc """ 
	$(getModelDocString(cFlowSoilProperties))
"""
cFlowSoilProperties