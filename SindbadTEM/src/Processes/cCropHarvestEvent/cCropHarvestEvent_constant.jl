export cCropHarvestEvent_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cCropHarvestEvent_constant{T1} <: cCropHarvestEvent
	P1::T1 = Inf | (-Inf, Inf) | "parameter 1" | "parameter 1 unit" | "parameter 1 timescale"
end
#! format: on

function define(params::cCropHarvestEvent_constant, forcing, land, helpers)
	return land
end

function precompute(params::cCropHarvestEvent_constant, forcing, land, helpers)
	return land
end

function compute(params::cCropHarvestEvent_constant, forcing, land, helpers)
	## Automatically generated sample code for basis. Modify, correct, and use. define, precompute, and update methods can use similar coding when needed. When not, they can simply be deleted. 
	@unpack_cCropHarvestEvent_constant params # unpack the model parameters
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

function update(params::cCropHarvestEvent_constant, forcing, land, helpers)
	return land
end

purpose(::Type{cCropHarvestEvent_constant}) = ""

@doc """ 

	$(getModelDocString(cCropHarvestEvent_constant))

---

# Extended help

*References*

*Versions*
 - 1.0 on 31.08.2026 [sol]

*Created by*
 - sol

"""
cCropHarvestEvent_constant

