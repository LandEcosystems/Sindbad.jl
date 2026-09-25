export cFlowReserves

abstract type cFlowReserves <: LandEcosystem end

purpose(::Type{cFlowReserves}) = "Internal vegetation carbon transfers to and from reserve pools."

includeApproaches(cFlowReserves, @__DIR__)

@doc """ 
	$(getModelDocString(cFlowReserves))
"""
cFlowReserves
