export cFlowStress

abstract type cFlowStress <: LandEcosystem end

purpose(::Type{cFlowStress}) = "Carbon transfer stressor from environmental factors."

includeApproaches(cFlowStress, @__DIR__)

@doc """ 
	$(getModelDocString(cFlowStress))
"""
cFlowStress
