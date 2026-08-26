export cCropHarvestIntensity_none


struct cCropHarvestIntensity_none <: cCropHarvestIntensity end

function define(params::cCropHarvestIntensity_none, forcing, land, helpers)
    @unpack_nt z_zero ⇐ land.constants

    frac_crop_harvest = z_zero

    @pack_nt frac_crop_harvest ⇒ land.diagnostics
	return land
end

purpose(::Type{cCropHarvestIntensity_none}) = "No crop harvest."

@doc """ 

	$(getModelDocString(cCropHarvestIntensity_none))

---

# Extended help

*References*

*Versions*
 - 1.0 on 25.08.2026 [sol]

*Created by*
 - sol

"""
cCropHarvestIntensity_none

