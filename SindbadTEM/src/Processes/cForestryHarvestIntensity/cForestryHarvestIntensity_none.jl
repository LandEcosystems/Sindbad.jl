export cForestryHarvestIntensity_none


struct cForestryHarvestIntensity_none <: cForestryHarvestIntensity end

function define(params::cForestryHarvestIntensity_none, forcing, land, helpers)
    @unpack_nt z_zero ⇐ land.constants

    frac_wood_harvest = z_zero

    @pack_nt frac_wood_harvest ⇒ land.diagnostics
	return land
end

purpose(::Type{cForestryHarvestIntensity_none}) = "No wood / forestry harvest."

@doc """ 

	$(getModelDocString(cForestryHarvestIntensity_none))

---

# Extended help

*References*

*Versions*
 - 1.0 on 25.08.2026 [sol]

*Created by*
 - sol

"""
cForestryHarvestIntensity_none

