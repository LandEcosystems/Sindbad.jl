export cMicrobialEfficiencycLit_texture

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiencycLit_texture{T1,T2} <: cMicrobialEfficiencycLit
    effA::T1 = 0.85 | (0.0, 1.0) | "Intercept of the linear of microbial carbon-transfer efficiency to soil texture." | "" | ""
    effB::T2 = 0.68 | (0.0, Inf) | "Sensitivity of microbial carbon-transfer efficiency to soil texture (silt+clay fraction)." | "" | ""
end
#! format: on

function define(params::cMicrobialEfficiencycLit_texture, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process does
    # not own leaves the efficiency to the other factors.
    c_flow_ME_f_cLit = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_ME_f_cLit ⇒ land.diagnostics
    return land
end

function precompute(params::cMicrobialEfficiencycLit_texture, forcing, land, helpers)
    ## unpack parameters
    @unpack_cMicrobialEfficiencycLit_texture params

    ## unpack land variables
    @unpack_nt begin
        c_flow_ME_f_cLit ⇐ land.diagnostics
        (c_flow_order, c_giver) ⇐ land.cCycleBase
        (st_clay, st_silt) ⇐ land.properties
    end

    ## calculate variables
    # One texture-driven efficiency for every transfer leaving the group, with no
    # distinction between pathways. Resolved through zix rather than by edge name, so it
    # holds on any structure and writes nothing where the group has no pools.
    microbial_efficiency = meTextureEfficiency(effA, effB, st_clay, st_silt)
    # helpers.pools.zix is read directly rather than through getZix(land.pools.cLit, ..),
    # because a structure without cLit pools has no land.pools.cLit array at all while
    # zix always carries the name, empty where the group is absent. That is what lets
    # this approach be selected on any structure.
    zix_cLit = helpers.pools.zix.cLit
    for fO ∈ c_flow_order
        c_giver[fO] ∈ zix_cLit || continue
        c_flow_ME_f_cLit = repElem(c_flow_ME_f_cLit, microbial_efficiency, c_flow_ME_f_cLit, c_flow_ME_f_cLit, fO)
    end

    ## pack land variables
    @pack_nt c_flow_ME_f_cLit ⇒ land.diagnostics
    return land
end

purpose(::Type{cMicrobialEfficiencycLit_texture}) = "Texture-dependent microbial carbon-transfer efficiency for every transfer leaving the litter pools."

@doc """

	$(getModelDocString(cMicrobialEfficiencycLit_texture))

---

# Extended help

The approach computes

`c_ME = clamp_zero_one(effA - effB * (mean(st_silt) + mean(st_clay)))`

through `meTextureEfficiency`, and assigns it to every active transfer whose giver is one
of the litter pools, with no distinction between pathways. Selecting `_texture` in all
three pool groups reproduces the single whole-vector texture approach this process family
used to carry.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cMicrobialEfficiencycLit_texture
