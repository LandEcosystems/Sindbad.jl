export drainage

abstract type drainage <: LandEcosystem end

purpose(::Type{drainage}) = "Drainage flux of water from upper to lower soil layers."

includeApproaches(drainage, @__DIR__)

@doc """ 
	$(getModelDocString(drainage))
"""
drainage

# define a common interface for updating for all drainage models
function update(params::drainage, forcing, land, helpers)

    ## unpack variables
    @unpack_nt begin
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
    end

    ## update variables
    soilW = addVec(soilW, ΔsoilW)

    for l in eachindex(ΔsoilW)
        @rep_elem zero(eltype(ΔsoilW)) ⇒ (ΔsoilW, l)
    end

    # pack land variables
    @pack_nt begin
    	soilW ⇒ land.pools
    	ΔsoilW ⇒ land.pools
    end
    return land
end
