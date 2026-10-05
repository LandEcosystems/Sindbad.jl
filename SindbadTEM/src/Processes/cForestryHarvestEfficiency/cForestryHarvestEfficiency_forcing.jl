export cForestryHarvestEfficiency_forcing

struct cForestryHarvestEfficiency_forcing <: cForestryHarvestEfficiency end

function compute(params::cForestryHarvestEfficiency_forcing, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        f_wood_harvest_efficiency ⇐ forcing
    end
    frac_wood_harvest_efficiency = f_wood_harvest_efficiency # in forcing called it f_wood_harvest 
    # ## pack land variables
    @pack_nt begin
        frac_wood_harvest_efficiency ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cForestryHarvestEfficiency_forcing}) = "Load the harvest fraction efficiency from the forcing. Harvest fraction efficiency is the proportion of the cVegPool killed by forestry activities that is abstracted from the system."

@doc """ 

	$(getModelDocString(cForestryHarvestEfficiency_forcing))

---

# Extended help

*References*

*Versions*
 - 1.0 on 25.08.2026 [sol]

*Created by*
 - sol

"""
cForestryHarvestEfficiency_forcing

