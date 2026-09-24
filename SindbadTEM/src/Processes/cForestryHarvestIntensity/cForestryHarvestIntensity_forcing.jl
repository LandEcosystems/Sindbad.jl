export cForestryHarvestIntensity_forcing

struct cForestryHarvestIntensity_forcing <: cForestryHarvestIntensity end

function compute(params::cForestryHarvestIntensity_forcing, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        f_wood_harvest_intensity ⇐ forcing
    end
    frac_wood_harvest_intensity = f_wood_harvest_intensity # in forcing called it f_wood_harvest_intensity
    # ## pack land variables
    @pack_nt begin
        frac_wood_harvest_intensity ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cForestryHarvestIntensity_forcing}) = "Load the harvest intensity fraction from the forcing. Harvest fraction intensity is the proportion of the cVegPools that is killed during a harvest event."

@doc """ 

	$(getModelDocString(cForestryHarvestIntensity_forcing))

---

# Extended help

*References*

*Versions*
 - 1.0 on 25.08.2026 [sol]

*Created by*
 - sol

"""
cForestryHarvestIntensity_forcing

