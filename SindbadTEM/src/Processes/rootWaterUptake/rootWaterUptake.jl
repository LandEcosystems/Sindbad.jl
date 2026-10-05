export rootWaterUptake

abstract type rootWaterUptake <: LandEcosystem end

purpose(::Type{rootWaterUptake}) = "Root water uptake from soil."

includeApproaches(rootWaterUptake, @__DIR__)

@doc """ 
	$(getModelDocString(rootWaterUptake))
"""
rootWaterUptake

# define a common update interface for all rootWaterUptake models
function update(params::rootWaterUptake, forcing, land, helpers)

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
