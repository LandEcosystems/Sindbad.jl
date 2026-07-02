export rwuPotential

abstract type rwuPotential <: LandEcosystem end

purpose(::Type{rwuPotential}) = "Potential of Root water uptake."

includeApproaches(rwuPotential, @__DIR__)

@doc """ 
	$(getModelDocString(rwuPotential))
"""
rwuPotential
