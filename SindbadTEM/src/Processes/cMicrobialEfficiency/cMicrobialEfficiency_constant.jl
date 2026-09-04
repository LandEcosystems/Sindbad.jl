export cMicrobialEfficiency_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiency_constant{T1} <: cMicrobialEfficiency
    constant_MicEff::T1 = 0.5 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of every decomposition flow, whichever pool group it leaves." | "fraction" | ""
end
#! format: on

function precompute(params::cMicrobialEfficiency_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_cMicrobialEfficiency_constant params

    ## unpack land variables
    @unpack_nt begin
        c_flow_ME_vec ⇐ land.diagnostics
        (c_flow_order, c_giver) ⇐ land.cCycleBase
    end

    ## calculate variables
    # One efficiency for every decomposition transfer, with no distinction between pool
    # groups or pathways. The three pool-group factors are deliberately not read, so this
    # holds whether or not they are selected.
    #
    # helpers.pools.zix is read directly rather than through getZix(land.pools.X, ..),
    # because a structure without a group's pools has no land.pools array for it at all
    # while zix always carries the name, empty where the group is absent.
    zix_decomposition = (helpers.pools.zix.cLit..., helpers.pools.zix.cMic...,
        helpers.pools.zix.cSoil...)
    for fO ∈ c_flow_order
        c_giver[fO] ∈ zix_decomposition || continue
        c_flow_ME_vec = repElem(c_flow_ME_vec, constant_MicEff, c_flow_ME_vec, c_flow_ME_vec, fO)
    end

    ## pack land variables
    @pack_nt c_flow_ME_vec ⇒ land.diagnostics
    return land
end

purpose(::Type{cMicrobialEfficiency_constant}) = "A single constant microbial carbon-transfer efficiency for every decomposition flow, whichever pool group it leaves."

@doc """

	$(getModelDocString(cMicrobialEfficiency_constant))

---

# Extended help

`constant_MicEff` is written into every active transfer whose giver is a litter,
microbial or soil carbon pool. Transfers leaving vegetation keep the neutral efficiency
of one, since litterfall is not microbial decomposition.

Set it to zero for the endpoint where all decomposed carbon respires and none is retained
by the receiving pool.

This is the one-parameter alternative to composing the three pool-group factors through
[`cMicrobialEfficiency_mult`](@ref). It ignores them, so it can be selected whether or not
they are, and it is equivalent to selecting `_constant` with the same value in all three
groups.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cMicrobialEfficiency_constant
