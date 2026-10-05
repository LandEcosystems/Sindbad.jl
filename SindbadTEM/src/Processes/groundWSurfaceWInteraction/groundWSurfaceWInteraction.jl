export groundWSurfaceWInteraction

abstract type groundWSurfaceWInteraction <: LandEcosystem end

purpose(::Type{groundWSurfaceWInteraction}) = "Water exchange between surface and groundwater."

includeApproaches(groundWSurfaceWInteraction, @__DIR__)

@doc """ 
	$(getModelDocString(groundWSurfaceWInteraction))
"""
groundWSurfaceWInteraction


# define a common update interface for all groundWSurfaceWInteraction models
function update(params::groundWSurfaceWInteraction, forcing, land, helpers)

    ## unpack variables
    @unpack_nt begin
        (surfaceW, groundW) ⇐ land.pools
        (ΔsurfaceW, ΔgroundW) ⇐ land.states
    end

    ## update storage pools
    groundW = addVec(groundW, ΔgroundW)
    surfaceW = addVec(surfaceW, ΔsurfaceW)

    for l in eachindex(ΔgroundW)
        @rep_elem zero(eltype(ΔgroundW)) ⇒ (ΔgroundW, l)
    end
    for l in eachindex(ΔsurfaceW)
        @rep_elem zero(eltype(ΔsurfaceW)) ⇒ (ΔsurfaceW, l)
    end

    ## pack land variables
    @pack_nt begin
        (groundW, surfaceW) ⇒ land.pools
        (ΔsurfaceW, ΔgroundW) ⇒ land.pools
    end
    return land
end