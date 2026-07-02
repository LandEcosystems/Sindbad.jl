export hydraulicConductivity

abstract type hydraulicConductivity <: LandEcosystem end

purpose(::Type{hydraulicConductivity}) = "Hydraulic conductivity and water-retention helper calculations."

includeApproaches(hydraulicConductivity, @__DIR__)

@doc """ 
	$(getModelDocString(hydraulicConductivity))
"""
hydraulicConductivity
