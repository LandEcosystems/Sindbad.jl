export plantForm

abstract type plantForm <: LandEcosystem end

purpose(::Type{plantForm}) = "Plant form of the ecosystem."

includeApproaches(plantForm, @__DIR__)

@doc """ 
	$(getModelDocString(plantForm))
"""
plantForm