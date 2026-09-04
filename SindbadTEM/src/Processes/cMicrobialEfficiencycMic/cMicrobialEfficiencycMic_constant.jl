export cMicrobialEfficiencycMic_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiencycMic_constant{T1} <: cMicrobialEfficiencycMic
    constant_MicEff_cMic::T1 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of every flow leaving a microbial pool." | "fraction" | ""
end
#! format: on

function define(params::cMicrobialEfficiencycMic_constant, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process does
    # not own leaves the efficiency to the other factors.
    c_flow_ME_f_cMic = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_ME_f_cMic ⇒ land.diagnostics
    return land
end

function precompute(params::cMicrobialEfficiencycMic_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_cMicrobialEfficiencycMic_constant params

    ## unpack land variables
    @unpack_nt begin
        c_flow_ME_f_cMic ⇐ land.diagnostics
        (c_flow_order, c_giver) ⇐ land.cCycleBase
    end

    ## calculate variables
    # One efficiency for every transfer leaving the group, with no distinction between
    # pathways. Resolved through zix rather than by edge name, so it holds on any
    # structure and writes nothing where the group has no pools.
    # helpers.pools.zix is read directly rather than through getZix(land.pools.cMic, ..),
    # because a structure without cMic pools has no land.pools.cMic array at all while
    # zix always carries the name, empty where the group is absent. That is what lets
    # this approach be selected on any structure.
    zix_cMic = helpers.pools.zix.cMic
    for fO ∈ c_flow_order
        c_giver[fO] ∈ zix_cMic || continue
        c_flow_ME_f_cMic = repElem(c_flow_ME_f_cMic, constant_MicEff_cMic, c_flow_ME_f_cMic, c_flow_ME_f_cMic, fO)
    end

    ## pack land variables
    @pack_nt c_flow_ME_f_cMic ⇒ land.diagnostics
    return land
end

purpose(::Type{cMicrobialEfficiencycMic_constant}) = "A single constant microbial carbon-transfer efficiency for every transfer leaving the microbial pools."

@doc """

	$(getModelDocString(cMicrobialEfficiencycMic_constant))

---

# Extended help

`constant_MicEff_cMic` is written into every active transfer whose giver is one of the
microbial pools. Set it to zero for the behaviour where all carbon decomposing out of this
group respires rather than arriving in the receiving pool.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cMicrobialEfficiencycMic_constant
