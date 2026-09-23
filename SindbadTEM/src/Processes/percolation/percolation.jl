export percolation

abstract type percolation <: LandEcosystem end

purpose(::Type{percolation}) = "Percolation through the top of soil"

includeApproaches(percolation, @__DIR__)

@doc """ 
	$(getModelDocString(percolation))
"""
percolation

# define a common update interface for all percolation models
function update(params::percolation, forcing, land, helpers)
    ## unpack variables
    @unpack_nt begin
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
    end

    ## update variables
    soilW = addVec(soilW, ΔsoilW)

    # reset soil moisture changes to zero
    for l in eachindex(ΔsoilW)
        @rep_elem zero(eltype(ΔsoilW)) ⇒ (ΔsoilW, l)
    end

    ## pack land variables
    @pack_nt begin
        soilW ⇒ land.pools
        ΔsoilW ⇒ land.pools
    end
    return land
end
