export groundWSoilWInteraction

abstract type groundWSoilWInteraction <: LandEcosystem end

purpose(::Type{groundWSoilWInteraction}) = "Groundwater-soil moisture interactions (e.g., capillary flux, water exchange)."

includeApproaches(groundWSoilWInteraction, @__DIR__)

@doc """ 
	$(getModelDocString(groundWSoilWInteraction))
"""
groundWSoilWInteraction


# define a common update interface for all groundWSoilWInteraction models
function update(params::groundWSoilWInteraction, forcing, land, helpers)

    ## unpack variables
    @unpack_nt begin
        (soilW, groundW) ⇐ land.pools
        (ΔsoilW, ΔgroundW) ⇐ land.states
    end

    ## update storage pools
	last_soilW = lastindex(soilW)
	@add_to_elem ΔsoilW[last_soilW] ⇒ (soilW, last_soilW, :soilW)


    groundW = addVec(groundW, ΔgroundW)

	@rep_elem zero(eltype(ΔsoilW)) ⇒ (ΔsoilW, last_soilW)

    for l in eachindex(ΔgroundW)
        @rep_elem zero(eltype(ΔgroundW)) ⇒ (ΔgroundW, l)
    end

    ## pack land variables
    @pack_nt begin
        (groundW, soilW) ⇒ land.pools
        (ΔsoilW, ΔgroundW) ⇒ land.pools
    end
    return land
end