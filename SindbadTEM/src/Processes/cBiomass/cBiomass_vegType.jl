export cBiomass_vegType


struct cBiomass_vegType <: cBiomass end

function compute(params::cBiomass_vegType, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools
    @unpack_nt veg_type_name ⇐ land.states

    ## calculate variables
    # summed straight out of cEco through zix, so a pool name that spans several cEco
    # slots contributes all of them and a name the structure lacks contributes
    # nothing
    cVegLeaf_sum = totalS_indices(cEco, helpers.pools.zix.cVegLeaf)
    cVegWood_sum = totalS_indices(cEco, helpers.pools.zix.cVegWood)
    cVegReserve_sum = totalS_indices(cEco, helpers.pools.zix.cVegReserve)
    cVegRoot_sum = totalS_indices(cEco, helpers.pools.zix.cVegRoot)
    aboveground_biomass = (cVegWood_sum + cVegLeaf_sum) + cVegReserve_sum * (cVegWood_sum + cVegLeaf_sum) / (cVegWood_sum + cVegLeaf_sum + cVegRoot_sum)


    aboveground_biomass = veg_type_name === :herb ? cVegWood_sum : aboveground_biomass

    @pack_nt begin
        aboveground_biomass ⇒ land.states
    end

	return land
end

purpose(::Type{cBiomass_vegType}) = "Same as `cBiomass_treeGrass_cVegReserveScaling`, but selects herbaceous vegetation from `land.states.veg_type_name` being `:herb` instead of from `frac_tree`."

@doc """

	$(getModelDocString(cBiomass_vegType))

---

# Extended help

*References*

*Versions*
 - 1.0 on 22.10.2026 [skoirala]

*Created by*
 - skoirala

"""
cBiomass_vegType

