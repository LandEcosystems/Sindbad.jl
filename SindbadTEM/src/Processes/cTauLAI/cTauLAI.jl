export cTauLAI

abstract type cTauLAI <: LandEcosystem end

purpose(::Type{cTauLAI}) = "Effect of LAI on turnover rates of carbon pools."

includeApproaches(cTauLAI, @__DIR__)

@doc """ 
	$(getModelDocString(cTauLAI))
"""
cTauLAI