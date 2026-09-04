export cMicrobialEfficiencycSoil_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiencycSoil_constant{T1} <: cMicrobialEfficiencycSoil
    constant_MicEff_cSoil::T1 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of every decomposition flow leaving a soil carbon pool." | "fraction" | ""
end
#! format: on

function define(params::cMicrobialEfficiencycSoil_constant, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process does
    # not own leaves the efficiency to the other factors.
    c_flow_ME_f_cSoil = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_ME_f_cSoil ⇒ land.diagnostics
    return land
end

function precompute(params::cMicrobialEfficiencycSoil_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_cMicrobialEfficiencycSoil_constant params

    ## unpack land variables
    @unpack_nt begin
        c_flow_ME_f_cSoil ⇐ land.diagnostics
        (c_flow_order, c_giver) ⇐ land.cCycleBase
    end

    ## calculate variables
    # One efficiency for every transfer leaving the group, with no distinction between
    # pathways. Resolved through zix rather than by edge name, so it holds on any
    # structure and writes nothing where the group has no pools.
    # helpers.pools.zix is read directly rather than through getZix(land.pools.cSoil, ..),
    # because a structure without cSoil pools has no land.pools.cSoil array at all while
    # zix always carries the name, empty where the group is absent. That is what lets
    # this approach be selected on any structure.
    zix_cSoil = helpers.pools.zix.cSoil
    for fO ∈ c_flow_order
        c_giver[fO] ∈ zix_cSoil || continue
        c_flow_ME_f_cSoil = repElem(c_flow_ME_f_cSoil, constant_MicEff_cSoil, c_flow_ME_f_cSoil, c_flow_ME_f_cSoil, fO)
    end

    ## pack land variables
    @pack_nt c_flow_ME_f_cSoil ⇒ land.diagnostics
    return land
end

purpose(::Type{cMicrobialEfficiencycSoil_constant}) = "A single constant microbial carbon-transfer efficiency for every transfer leaving the soil carbon pools."

@doc """

	$(getModelDocString(cMicrobialEfficiencycSoil_constant))

---

# Extended help

`constant_MicEff_cSoil` is written into every active transfer whose giver is one of the
soil carbon pools. Set it to zero for the behaviour where all carbon decomposing out of this
group respires rather than arriving in the receiving pool.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cMicrobialEfficiencycSoil_constant
