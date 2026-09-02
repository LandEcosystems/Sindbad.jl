export cBiomass_simple

struct cBiomass_simple <: cBiomass end

function compute(params::cBiomass_simple, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools
    ## calculate variables    
    # summed straight out of cEco through zix, so a pool name that spans several cEco
    # slots contributes all of them and a name the structure lacks contributes nothing
    cVegLeaf_sum = totalS_indices(cEco, helpers.pools.zix.cVegLeaf)
    cVegWood_sum = totalS_indices(cEco, helpers.pools.zix.cVegWood)
    aboveground_biomass = cVegWood_sum + cVegLeaf_sum # the assumption is that the wood and leaf pools are aboveground!

    @pack_nt begin
        aboveground_biomass ⇒ land.states
    end
    return land
end


purpose(::Type{cBiomass_simple}) = "Calculates AGB `simply` as the sum of wood and leaf carbon pools."

@doc """

$(getModelDocString(cBiomass_simple))

---

# Extended help

*References*

*Versions*

*Created by*
"""
cBiomass_simple