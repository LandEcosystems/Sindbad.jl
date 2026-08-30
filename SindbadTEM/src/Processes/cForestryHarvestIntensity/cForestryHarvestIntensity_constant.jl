export cForestryHarvestIntensity_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cForestryHarvestIntensity_constant{
	T1 # constant_frac_wood_harvest_intensity
} <: cForestryHarvestIntensity
	constant_frac_wood_harvest_intensity::T1 = 0.9 | (0.0, 1.0) | "Fraction of the harvestable vegetation live carbon pools carbon pools that is killed by the harvest event" | "fraction" | ""
end
#! format: on

function precompute(params::cForestryHarvestIntensity_constant, forcing, land, helpers)
	@unpack_cForestryHarvestIntensity_constant params
	frac_wood_harvest_intensity = constant_frac_wood_harvest_intensity
    @pack_nt begin
        frac_wood_harvest_intensity ⇒ land.diagnostics
    end
	return land
end

purpose(::Type{cForestryHarvestIntensity_constant}) = "To determine globally constant fractions of wood harvest efficiency and intensity from forestry. Intensity reflects how much of the live cVegPools is killed/damaged during a harvest event; in an area basis, this would reflect a portion of the wood/forest that would not die during harvest. Intensity reflects how much of the killed cVegPools is removed from the system, turned into wood/forestry products."

@doc """ 

	$(getModelDocString(cForestryHarvestIntensity_constant))

---

# Extended help

*References*

*Versions*
 - 1.0 on 26.08.2026 [sol]

*Created by*
 - sol

"""
cForestryHarvestIntensity_constant

