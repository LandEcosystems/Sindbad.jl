export cCropHarvestEfficiency_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cCropHarvestEfficiency_constant{
	T1 # constant_frac_crop_harvest_efficiency
} <: cCropHarvest
	constant_frac_crop_harvest_efficiency::T1 = 0.8 | (0, 1) | "Fraction of the harvestable vegetation carbon pools that is removed from an ecosystem in a harvest event" | "fraction" | ""
end
#! format: on

function precompute(params::cCropHarvestEfficiency_constant, forcing, land, helpers)
	frac_crop_harvest_efficiency = constant_frac_crop_harvest_efficiency
    @pack_nt begin
        frac_crop_harvest_efficiency ⇒ land.diagnostics
    end
	return land
end

purpose(::Type{cCropHarvestEfficiency_constant}) = "To determine globally constant fractions of crop harvest efficiency and intensity. Intensity reflects how much of the live cVegPools is killed/damaged during a harvest event; in an area basis, this would reflect a portion of the crop that would not die during harvest. Efficiency reflects how much of the killed cVegPools is removed from the system, turned into crop products."

@doc """ 

	$(getModelDocString(cCropHarvestEfficiency_constant))

---

# Extended help

*References*

*Versions*
 - 1.0 on 26.08.2026 [sol]

*Created by*
 - sol

"""
cCropHarvestEfficiency_constant

