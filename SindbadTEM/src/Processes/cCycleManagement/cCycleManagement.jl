export cCycleManagement

abstract type cCycleManagement <: LandEcosystem end

purpose(::Type{cCycleManagement}) = "Agriculture and forestry"

includeApproaches(cCycleManagement, @__DIR__)

@doc """ 
	$(getModelDocString(cCycleManagement))
"""
cCycleManagement

