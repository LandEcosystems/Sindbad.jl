export plantHydraulics

abstract type plantHydraulics <: LandEcosystem end

purpose(::Type{plantHydraulics}) = "Plant water potentials, conductances, hydraulic stress, and coupled root water uptake."

includeApproaches(plantHydraulics, @__DIR__)

@doc """
    $(getModelDocString(plantHydraulics))
"""
plantHydraulics
