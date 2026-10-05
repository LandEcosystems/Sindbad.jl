export cForestryHarvestEvent_forcing


struct cForestryHarvestEvent_forcing <: cForestryHarvestEvent end

function compute(params::cForestryHarvestEvent_forcing, forcing, land, helpers)
	@unpack_nt f_is_wood_harvested ⇐ forcing
	is_wood_harvested = f_is_wood_harvested
    @pack_nt is_wood_harvested ⇒ land.diagnostics
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

