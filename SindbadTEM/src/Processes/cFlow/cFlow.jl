export cFlow

abstract type cFlow <: LandEcosystem end

purpose(::Type{cFlow}) = "Transfer rates for carbon flow between different vegetation pools."

includeApproaches(cFlow, @__DIR__)

@doc """ 
	$(getModelDocString(cFlow))
"""
cFlow
