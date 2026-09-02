export LAI_cVegLeaf

#! format: off
@bounds @describe @units @timescale @with_kw struct LAI_cVegLeaf{T1} <: LAI
    SLA::T1 = 0.016 | (0.01, 0.024) | "specific leaf area" | "m^2.gC^-1" | ""
end
#! format: on

function compute(params::LAI_cVegLeaf, forcing, land, helpers)
    ## unpack parameters
    @unpack_LAI_cVegLeaf params

    @unpack_nt cEco ⇐ land.pools

    ## calculate variables
    # summed straight out of cEco through zix, so a pool name that spans several cEco
    # slots contributes all of them and a name the structure lacks contributes nothing
    cVegLeafTotal = totalS_indices(cEco, helpers.pools.zix.cVegLeaf)
    LAI = cVegLeafTotal * SLA

    ## pack land variables
    @pack_nt LAI ⇒ land.states
    return land
end

purpose(::Type{LAI_cVegLeaf}) = "LAI as a function of cVegLeaf and SLA."

@doc """

$(getModelDocString(LAI_cVegLeaf))

---

# Extended help

*References*

*Versions*
 - 1.0 on 05.05.2020 [sbesnard]

*Created by*
 - sbesnard
"""
LAI_cVegLeaf
