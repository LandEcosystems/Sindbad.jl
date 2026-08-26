export cCropHarvestIntensity_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cCropHarvestIntensity_constant{
	T1 # constant_frac_crop_harvest_intensity
} <: cCropHarvest
	constant_frac_crop_harvest_intensity::T1 = 1.0 | (0, 1) | "Fraction of the harvestable vegetation live carbon pools carbon pools that is killed by the harvest event" | "fraction" | ""
end
#! format: on

function precompute(params::cCropHarvestIntensity_constant, forcing, land, helpers)
	frac_crop_harvest = constant_frac_crop_harvest 
    @pack_nt begin
        frac_crop_harvest_intensity ⇒ land.diagnostics
    end
	return land
end

purpose(::Type{cCropHarvestIntensity_constant}) = "To determine globally constant fractions of crop harvest efficiency and intensity. Intensity reflects how much of the live cVegPools is killed/damaged during a harvest event; in an area basis, this would reflect a portion of the crop that would not die during harvest. Intensity reflects how much of the killed cVegPools is removed from the system, turned into crop products."

@doc """ 

	$(getModelDocString(cCropHarvestIntensity_constant))

---

# Extended help

*References*

*Versions*
 - 1.0 on 26.08.2026 [sol]

*Created by*
 - sol

"""
cCropHarvestIntensity_constant

