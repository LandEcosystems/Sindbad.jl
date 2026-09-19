export groundWRecharge

abstract type groundWRecharge <: LandEcosystem end

purpose(::Type{groundWRecharge}) = "Groundwater recharge."

includeApproaches(groundWRecharge, @__DIR__)

@doc """ 
	$(getModelDocString(groundWRecharge))
"""
groundWRecharge

# define a common update interface for all groundWRecharge models
function update(params::groundWRecharge, forcing, land, helpers)

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