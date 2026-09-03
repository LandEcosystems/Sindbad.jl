export fAPAR_cVegLeaf

#! format: off
@bounds @describe @units @timescale @with_kw struct fAPAR_cVegLeaf{T1} <: fAPAR
    k_extinction::T1 = 0.005 | (0.0005, 0.05) | "effective light extinction coefficient" | "" | ""
end
#! format: on

function compute(params::fAPAR_cVegLeaf, forcing, land, helpers)
    ## unpack parameters
    @unpack_fAPAR_cVegLeaf params

    ## unpack land variables
    @unpack_nt begin
        cEco ⇐ land.pools
    end

    ## calculate variables
    # summed straight out of cEco through zix, so a pool name that spans several cEco
    # slots contributes all of them and a name the structure lacks contributes
    # nothing
    cVegLeaf_sum = totalS_indices(cEco, helpers.pools.zix.cVegLeaf)
    fAPAR = one(k_extinction) - exp(-(cVegLeaf_sum * k_extinction))

    ## pack land variables
    @pack_nt fAPAR ⇒ land.states
    return land
end

purpose(::Type{fAPAR_cVegLeaf}) = "fAPAR based on the carbon pool of leaves, specific leaf area (SLA), and kLAI."

@doc """

$(getModelDocString(fAPAR_cVegLeaf))

---

# Extended help

*References*

*Versions*
 - 1.0 on 24.04.2021 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko
"""
fAPAR_cVegLeaf
