export cFire

abstract type cFire <: LandEcosystem end

purpose(::Type{cFire}) = "Carbon loss due to fire disturbance events."

includeApproaches(cFire, @__DIR__)

@doc """ 
	$(getModelDocString(cFire))
"""
cFire
