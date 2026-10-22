export fAPAR_cVegLeafBareFrac

#! format: off
@bounds @describe @units @timescale @with_kw struct fAPAR_cVegLeafBareFrac{T1} <: fAPAR
    k_extinction::T1 = 0.005 | (0.0005, 0.05) | "effective light extinction coefficient" | "" | ""
end
#! format: on

function compute(params::fAPAR_cVegLeafBareFrac, forcing, land, helpers)
    ## unpack parameters
    @unpack_fAPAR_cVegLeafBareFrac params

    ## unpack land variables
    @unpack_nt begin
        cEco ⇐ land.pools
        frac_vegetation ⇐ land.states
    end
    ## calculate variables
    # summed straight out of cEco through zix, so a pool name that spans several cEco
    # slots contributes all of them and a name the structure lacks contributes
    # nothing
    cVegLeaf_sum = totalS_indices(cEco, helpers.pools.zix.cVegLeaf)
    # fAPAR is per m2 of vegetated area, fAPAR_grid per m2 of grid cell
    fAPAR = one(k_extinction) - exp(-(cVegLeaf_sum * k_extinction))
    fAPAR_grid = fAPAR * frac_vegetation
    # Cross check frac_vegetation from NetCDF files!
    # TODO:  tree_frac (1km), Ranits's, mix, use table is available if not keep it!
    #
    # ? make sure that frac_vegetation is consistent with Ranit's table!
    ## pack land variables
    @pack_nt (fAPAR, fAPAR_grid) ⇒ land.states
    return land
end

purpose(::Type{fAPAR_cVegLeafBareFrac}) = "fAPAR of the vegetated area based on the carbon pool of leaves, and fAPAR of the grid cell scaled by the vegetation fraction."

@doc """

$(getModelDocString(fAPAR_cVegLeafBareFrac))

---

# Extended help

*References*

*Versions*
 - 1.0 on 24.04.2021 [skoirala | @dr-ko]

*Created by:*
 - Nuno & skoirala
"""
fAPAR_cVegLeafBareFrac
