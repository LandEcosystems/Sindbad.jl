export cForestryHarvestEfficiency_none


struct cForestryHarvestEfficiency_none <: cForestryHarvestEfficiency end

function define(params::cForestryHarvestEfficiency_none, forcing, land, helpers)
    @unpack_nt z_zero ⇐ land.constants

    frac_wood_harvest = z_zero

    @pack_nt frac_wood_harvest ⇒ land.diagnostics
	return land
end

purpose(::Type{cForestryHarvestEfficiency_none}) = "No forestry wood harvest efficiency."

@doc """ 

	$(getModelDocString(cForestryHarvestEfficiency_none))

---

# Extended help

*References*

*Versions*
 - 1.0 on 25.08.2026 [sol]

*Created by*
 - sol

"""
cForestryHarvestEfficiency_none

