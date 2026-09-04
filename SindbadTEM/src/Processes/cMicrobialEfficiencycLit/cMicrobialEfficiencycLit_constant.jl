export cMicrobialEfficiencycLit_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiencycLit_constant{T1} <: cMicrobialEfficiencycLit
    constant_MicEff_cLit::T1 = 0.5 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of every decomposition flow leaving a litter pool." | "fraction" | ""
end
#! format: on

function define(params::cMicrobialEfficiencycLit_constant, forcing, land, helpers)
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

function precompute(params::cMicrobialEfficiencycLit_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_cMicrobialEfficiencycLit_constant params

    ## unpack land variables
    @unpack_nt begin
        c_flow_ME_f_cLit ⇐ land.diagnostics
        (c_flow_order, c_giver) ⇐ land.cCycleBase
    end

    ## calculate variables
    # One efficiency for every transfer leaving the group, with no distinction between
    # pathways. Resolved through zix rather than by edge name, so it holds on any
    # structure and writes nothing where the group has no pools.
    # helpers.pools.zix is read directly rather than through getZix(land.pools.cLit, ..),
    # because a structure without cLit pools has no land.pools.cLit array at all while
    # zix always carries the name, empty where the group is absent. That is what lets
    # this approach be selected on any structure.
    zix_cLit = helpers.pools.zix.cLit
    for fO ∈ c_flow_order
        c_giver[fO] ∈ zix_cLit || continue
        c_flow_ME_f_cLit = repElem(c_flow_ME_f_cLit, constant_MicEff_cLit, c_flow_ME_f_cLit, c_flow_ME_f_cLit, fO)
    end

    ## pack land variables
    @pack_nt c_flow_ME_f_cLit ⇒ land.diagnostics
    return land
end

purpose(::Type{cMicrobialEfficiencycLit_constant}) = "A single constant microbial carbon-transfer efficiency for every transfer leaving the litter pools."

@doc """

	$(getModelDocString(cMicrobialEfficiencycLit_constant))

---

# Extended help

`constant_MicEff_cLit` is written into every active transfer whose giver is one of the
litter pools. Set it to zero for the behaviour where all carbon decomposing out of this
group respires rather than arriving in the receiving pool.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cMicrobialEfficiencycLit_constant
