export cForestryHarvestEvent_none


struct cForestryHarvestEvent_none <: cForestryHarvestEvent end

function define(params::cForestryHarvestEvent_none, forcing, land, helpers)
	@unpack_nt z_zero ⇐ land.constants
	is_wood_harvested = z_zero
    @pack_nt is_wood_harvested ⇒ land.diagnostics
	return land
end

purpose(::Type{cForestryHarvestEvent_none}) = ""

@doc """ 

	$(getModelDocString(cForestryHarvestEvent_none))

---

# Extended help

*References*

*Versions*
 - 1.0 on 31.08.2026 [sol]

*Created by*
 - sol

"""
cForestryHarvestEvent_none

