export percolation_rain


struct percolation_rain <: percolation end

function define(params::percolation_rain, forcing, land, helpers)
	return land
end

function precompute(params::percolation_rain, forcing, land, helpers)
	return land
end

function compute(params::percolation_rain, forcing, land, helpers)
	## unpack NT land
	@unpack_nt begin
		rain ⇐ land.fluxes
		ΔsoilW ⇐ land.pools
	end
	@add_to_elem rain ⇒ (ΔsoilW, 1)

	@pack_nt begin
		ΔsoilW ⇒ land.pools
	end

	return land
end

function update(params::percolation_rain, forcing, land, helpers)
	return land
end

purpose(::Type{percolation_rain}) = "calculate percolation = rain, assuming no surface runoff losses"

@doc """ 

	$(getModelDocString(percolation_rain))

---

# Extended help

*References*

*Versions*
 - 1.0 on 16.12.2025 [skoirala]

*Created by*
 - skoirala

"""
percolation_rain

