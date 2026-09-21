export cFlowLitterfall

abstract type cFlowLitterfall <: LandEcosystem end

purpose(::Type{cFlowLitterfall}) = "Vegetation carbon loss rates to litter, including background turnover and phenological shedding."

includeApproaches(cFlowLitterfall, @__DIR__)

@doc """ 
	$(getModelDocString(cFlowLitterfall))
"""
cFlowLitterfall
