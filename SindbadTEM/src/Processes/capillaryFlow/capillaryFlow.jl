export capillaryFlow

abstract type capillaryFlow <: LandEcosystem end

purpose(::Type{capillaryFlow}) = "Capillary flux of water from lower to upper soil layers (upward soil moisture movement)."

includeApproaches(capillaryFlow, @__DIR__)

@doc """ 
	$(getModelDocString(capillaryFlow))
"""
capillaryFlow

# define a common update interface for all capillaryFlow models
function update(params::capillaryFlow, forcing, land, helpers)

    ## unpack variables
    @unpack_nt begin
        (soilW, ΔsoilW) ⇐ land.pools
    end

    ## update variables
    soilW = addVec(soilW, ΔsoilW)

    for l in eachindex(ΔsoilW)
        @rep_elem zero(eltype(ΔsoilW)) ⇒ (ΔsoilW, l)
    end

    ## pack land variables
    @pack_nt begin
        (soilW, ΔsoilW) ⇒ land.pools
    end
    return land
end