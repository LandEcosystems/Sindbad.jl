export cCropHarvestEvent_forcing

struct cCropHarvestEvent_forcing <: cCropHarvestEvent end

function compute(params::cCropHarvestEvent_forcing, forcing, land, helpers)
	@unpack_nt f_is_crop_harvested ⇐ forcing
	is_crop_harvested = f_is_crop_harvested
    @pack_nt is_crop_harvested ⇒ land.diagnostics
	return land
end

purpose(::Type{cCropHarvestEvent_forcing}) = ""

@doc """ 

	$(getModelDocString(cCropHarvestEvent_forcing))

---

# Extended help

*References*

*Versions*
 - 1.0 on 31.08.2026 [sol]

*Created by*
 - sol

"""
cCropHarvestEvent_forcing

