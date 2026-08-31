export cForestryHarvestEvent_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cForestryHarvestEvent_constant{T1} <: cForestryHarvestEvent
	P1::T1 = Inf | (-Inf, Inf) | "parameter 1" | "parameter 1 unit" | "parameter 1 timescale"
end
#! format: on

function define(params::cForestryHarvestEvent_constant, forcing, land, helpers)
	return land
end

function precompute(params::cForestryHarvestEvent_constant, forcing, land, helpers)
	return land
end

function compute(params::cForestryHarvestEvent_constant, forcing, land, helpers)
	## Automatically generated sample code for basis. Modify, correct, and use. define, precompute, and update methods can use similar coding when needed. When not, they can simply be deleted. 
	@unpack_cForestryHarvestEvent_constant params # unpack the model parameters
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

function update(params::cForestryHarvestEvent_constant, forcing, land, helpers)
	return land
end

purpose(::Type{cForestryHarvestEvent_constant}) = ""

@doc """ 

	$(getModelDocString(cForestryHarvestEvent_constant))

---

# Extended help

*References*

*Versions*
 - 1.0 on 31.08.2026 [sol]

*Created by*
 - sol

"""
cForestryHarvestEvent_constant

