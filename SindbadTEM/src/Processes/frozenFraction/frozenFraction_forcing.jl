export frozenFraction_forcing


struct frozenFraction_forcing <: frozenFraction end

function precompute(params::frozenFraction_forcing, forcing, land, helpers)
	@unpack_nt z_zero ⇐ land.constants
	
	frac_frozen_soil = z_zero

	@pack_nt frac_frozen_soil ⇒ land.states

	return land
end

function compute(params::frozenFraction_forcing, forcing, land, helpers)
	## Automatically generated sample code for basis. Modify, correct, and use. define, precompute, and update methods can use similar coding when needed. When not, they can simply be deleted. 
	## unpack NT forcing
	@unpack_nt f_frac_frozen_soil ⇐ forcing

	frac_frozen_soil = f_frac_frozen_soil

	## pack land variables
	@pack_nt frac_frozen_soil ⇒ land.states

	return land
end


purpose(::Type{frozenFraction_forcing}) = "Gets frozen fraction from forcing"

@doc """ 

	$(getModelDocString(frozenFraction_forcing))

---

# Extended help

*References*

*Versions*
 - 1.0 on 04.08.2026 [skoirala]

*Created by*
 - skoirala

"""
frozenFraction_forcing

