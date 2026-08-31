export cForestryHarvestEvent_forcing


struct cForestryHarvestEvent_forcing <: cForestryHarvestEvent end

function define(params::cForestryHarvestEvent_forcing, forcing, land, helpers)
	return land
end

function precompute(params::cForestryHarvestEvent_forcing, forcing, land, helpers)
	return land
end

function compute(params::cForestryHarvestEvent_forcing, forcing, land, helpers)
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

function update(params::cForestryHarvestEvent_forcing, forcing, land, helpers)
	return land
end

purpose(::Type{cForestryHarvestEvent_forcing}) = ""

@doc """ 

	$(getModelDocString(cForestryHarvestEvent_forcing))

---

# Extended help

*References*

*Versions*
 - 1.0 on 31.08.2026 [sol]

*Created by*
 - sol

"""
cForestryHarvestEvent_forcing

