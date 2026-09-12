export runoffBase

abstract type runoffBase <: LandEcosystem end

purpose(::Type{runoffBase}) = "Baseflow."

includeApproaches(runoffBase, @__DIR__)

@doc """ 
	$(getModelDocString(runoffBase))
"""
runoffBase

# define a common update interface for all runoffBase models
function update(params::runoffBase, forcing, land, helpers)

    ## unpack variables
    @unpack_nt begin
        (groundW) ⇐ land.pools
        (ΔgroundW) ⇐ land.pools
    end
    groundW = addVec(groundW, ΔgroundW)
    for l in eachindex(ΔgroundW)
        @rep_elem zero(eltype(ΔgroundW)) ⇒ (ΔgroundW, l)
    end

    ## pack land variables
    @pack_nt begin
        (groundW, ΔgroundW) ⇒ land.pools
    end
    return land
end
