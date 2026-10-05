export runoffSurface

abstract type runoffSurface <: LandEcosystem end

purpose(::Type{runoffSurface}) = "Surface runoff generation."

includeApproaches(runoffSurface, @__DIR__)

@doc """ 
	$(getModelDocString(runoffSurface))
"""
runoffSurface

# define a common update interface for all runoffSurface models
function update(::runoffSurface, forcing, land, helpers)
    ## unpack variables
    @unpack_nt begin
        surfaceW ⇐ land.pools
        ΔsurfaceW ⇐ land.pools
    end

    ## update storage pools
    surfaceW = addVec(surfaceW, ΔsurfaceW)

    for l in eachindex(ΔsurfaceW)
        @rep_elem zero(eltype(ΔsurfaceW)) ⇒ (ΔsurfaceW, l)
    end

    ## pack land variables
    @pack_nt begin
        surfaceW ⇒ land.pools
        ΔsurfaceW ⇒ land.pools
    end
    return land
end
