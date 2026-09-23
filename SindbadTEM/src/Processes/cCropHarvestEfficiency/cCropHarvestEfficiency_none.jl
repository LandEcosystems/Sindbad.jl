export cCropHarvestEfficiency_none


struct cCropHarvestEfficiency_none <: cCropHarvestEfficiency end

function define(params::cCropHarvestEfficiency_none, forcing, land, helpers)
    @unpack_nt z_zero ⇐ land.constants

    frac_crop_harvest_efficiency = z_zero

    @pack_nt frac_crop_harvest_efficiency ⇒ land.diagnostics
	return land
end

purpose(::Type{cCropHarvestEfficiency_none}) = "No crop harvest efficiency."

@doc """ 

	$(getModelDocString(cCropHarvestEfficiency_none))

---

# Extended help

*References*

*Versions*
 - 1.0 on 25.08.2026 [sol]

*Created by*
 - sol

"""
cCropHarvestEfficiency_none

