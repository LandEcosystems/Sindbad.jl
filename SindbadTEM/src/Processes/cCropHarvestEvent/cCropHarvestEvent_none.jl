export cCropHarvestEvent_none


struct cCropHarvestEvent_none <: cCropHarvestEvent end

function define(params::cCropHarvestEvent_none, forcing, land, helpers)
	return land
end

function precompute(params::cCropHarvestEvent_none, forcing, land, helpers)
	return land
end

function compute(params::cCropHarvestEvent_none, forcing, land, helpers)
	## Automatically generated sample code for basis. Modify, correct, and use. define, precompute, and update methods can use similar coding when needed. When not, they can simply be deleted. 
	## unpack NT forcing
	# @unpack_nt f_variable ⇐ forcing

	## unpack NT land
	# @unpack_nt begin
		# flux_variable ⇐ land.fluxes
		# state_variable ⇐ land.states
	# end

	## Do calculations

	## pack land variables
	# @pack_nt new_diagnostic_variable ⇒ land.diagnostics

	return land
end

function update(params::cCropHarvestEvent_none, forcing, land, helpers)
	return land
end

purpose(::Type{cCropHarvestEvent_none}) = ""

@doc """ 

	$(getModelDocString(cCropHarvestEvent_none))

---

# Extended help

*References*

*Versions*
 - 1.0 on 31.08.2026 [sol]

*Created by*
 - sol

"""
cCropHarvestEvent_none

