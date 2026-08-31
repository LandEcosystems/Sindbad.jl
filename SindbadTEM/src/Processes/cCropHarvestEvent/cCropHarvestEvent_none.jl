export cCropHarvestEvent_none


struct cCropHarvestEvent_none <: cCropHarvestEvent end

function define(params::cCropHarvestEvent_none, forcing, land, helpers)
	@unpack_nt z_zero ⇐ land.constants
	is_crop_harvested = z_zero
    @pack_nt is_crop_harvested ⇒ land.diagnostics
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

