export cCropHarvestEfficiency_forcing

struct cCropHarvestEfficiency_forcing <: cCropHarvestEfficiency end

function compute(params::cCropHarvestEfficiency_forcing, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        f_crop_harvest_efficiency ⇐ forcing
    end
    frac_crop_harvest_efficiency = f_crop_harvest_efficiency # in forcing called it f_crop_harvest 
    # ## pack land variables
    @pack_nt begin
        frac_crop_harvest_efficiency ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cCropHarvestEfficiency_forcing}) = "Load the harvest fraction efficiency from the forcing. Harvest fraction efficiency is the proportion of the cVegPool killed for crops that is abstracted from the system."

@doc """ 

	$(getModelDocString(cCropHarvestEfficiency_forcing))

---

# Extended help

*References*

*Versions*
 - 1.0 on 25.08.2026 [sol]

*Created by*
 - sol

"""
cCropHarvestEfficiency_forcing

