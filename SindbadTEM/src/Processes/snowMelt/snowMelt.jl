export snowMelt

abstract type snowMelt <: LandEcosystem end

purpose(::Type{snowMelt}) = "Snowmelt."

includeApproaches(snowMelt, @__DIR__)

@doc """ 
	$(getModelDocString(snowMelt))
"""
snowMelt


# define a common update interface for all snowMelt models
function update(params::snowMelt, forcing, land, helpers)
    ## unpack variables
    @unpack_nt begin
        snowW ⇐ land.pools
        ΔsnowW ⇐ land.pools
    end

    # update snow pack
    snowW = addVec(snowW, ΔsnowW)

    # reset delta storage
    for l in eachindex(ΔsnowW)
        @rep_elem zero(eltype(ΔsnowW)) ⇒ (ΔsnowW, l)
    end

    ## pack land variables
    @pack_nt begin
        snowW ⇒ land.pools
        ΔsnowW ⇒ land.pools
    end
    return land
end
