export evaporation

abstract type evaporation <: LandEcosystem end

purpose(::Type{evaporation}) = "Bare soil evaporation."

includeApproaches(evaporation, @__DIR__)

@doc """ 
	$(getModelDocString(evaporation))
"""
evaporation

# define a common update interface for all evaporation models
function update(params::evaporation, forcing, land, helpers)
    @unpack_evaporation_bareFraction params

    ## unpack variables
    @unpack_nt begin
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
    end

    @add_to_elem ΔsoilW[1] ⇒ (soilW, 1, :soilW)

    @rep_elem zero(ΔsoilW) ⇒ (ΔsoilW, 1)

    ## pack land variables
    @pack_nt begin
    	soilW ⇒ land.pools
    	ΔsoilW ⇒ land.pools
    end
    return land
end