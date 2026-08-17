export cBiomass_treeGrass

struct cBiomass_treeGrass <: cBiomass end

function compute(params::cBiomass_treeGrass, forcing, land, helpers)

    @unpack_nt (cVegWood, cVegLeaf) ⇐ land.pools
    @unpack_nt frac_tree ⇐ land.states

    ## calculate variables    
    cVegLeaf_sum = totalS(cVegLeaf)
    cVegWood_sum = totalS(cVegWood)
    aboveground_biomass = cVegWood_sum + cVegLeaf_sum # the assumption is that the wood and leaf pools are aboveground!
    aboveground_biomass = ifelse(frac_tree > 0, aboveground_biomass, cVegWood_sum)

    @pack_nt begin
        aboveground_biomass ⇒ land.states
    end
    return land
end


purpose(::Type{cBiomass_treeGrass}) = "Considers the tree-grass fraction to include different vegetation pools while calculating AGB. For Eddy Covariance sites with tree cover, AGB = leaf + wood biomass. For grass-only sites, AGB is set to the wood biomass, which is constrained to be near 0 after optimization."

@doc """

$(getModelDocString(cBiomass_treeGrass))

---

# Extended help

*References*

*Versions*

*Created by*
"""
cBiomass_treeGrass
