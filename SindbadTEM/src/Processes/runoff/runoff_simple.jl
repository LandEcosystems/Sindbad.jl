export runoff_simple

#! format: off
@bounds @describe @units @timescale @with_kw struct runoff_simple{T1} <: runoff
	k_runoff::T1 = 0.001 | (0.001, 0.10) | "runoff rate" | "day-1" | "day"
end
#! format: on

function define(params::runoff_simple, forcing, land, helpers)
	return land
end

function precompute(params::runoff_simple, forcing, land, helpers)
	return land
end

function compute(params::runoff_simple, forcing, land, helpers)
	## Automatically generated sample code for basis. Modify, correct, and use. define, precompute, and update methods can use similar coding when needed. When not, they can simply be deleted. 	
	@unpack_runoff_simple params # unpack the model parameters
	@unpack_nt begin
		soilW ⇐ land.pools
		ΔsoilW ⇐ land.pools
	end
	runoff = k_runoff * (soilW[1] + ΔsoilW[1])
    @add_to_elem -runoff ⇒ (ΔsoilW, 1)
	@pack_nt begin
		runoff ⇒ land.fluxes
		ΔsoilW ⇒ land.pools
	end
	return land
end

function update(params::runoff_simple, forcing, land, helpers)
	return land
end

purpose(::Type{runoff_simple}) = "calculates runoff as a simple linear function of soil moisture"

@doc """ 

	$(getModelDocString(runoff_simple))

---

# Extended help

*References*

*Versions*
 - 1.0 on 16.12.2025 [skoirala]

*Created by*
 - skoirala

"""
runoff_simple

