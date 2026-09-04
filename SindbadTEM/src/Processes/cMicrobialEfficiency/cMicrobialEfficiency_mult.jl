export cMicrobialEfficiency_mult

struct cMicrobialEfficiency_mult <: cMicrobialEfficiency end

function precompute(params::cMicrobialEfficiency_mult, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_flow_ME_f_cLit ⇐ land.diagnostics
        c_flow_ME_f_cMic ⇐ land.diagnostics
        c_flow_ME_f_cSoil ⇐ land.diagnostics
        c_flow_ME_vec ⇐ land.diagnostics
    end

    ## calculate variables
    # Each factor is one on every flow it does not own, and the three own disjoint giver
    # pools, so the product of the factors is the efficiency itself. There is no base
    # term to multiply onto, unlike c_eco_k_base in cTau_mult, and the product is really
    # an assembly: at most one factor is ever away from one on a given flow.
    for i ∈ eachindex(c_flow_ME_vec)
        tmp = c_flow_ME_f_cLit[i] * c_flow_ME_f_cMic[i] * c_flow_ME_f_cSoil[i]
        c_flow_ME_vec = repElem(c_flow_ME_vec, tmp, c_flow_ME_vec, c_flow_ME_vec, i)
    end

    ## pack land variables
    @pack_nt c_flow_ME_vec ⇒ land.diagnostics
    return land
end

purpose(::Type{cMicrobialEfficiency_mult}) = "Combines the litter, microbial, and soil pool-group controls of microbial carbon-transfer efficiency."

@doc """

	$(getModelDocString(cMicrobialEfficiency_mult))

---

# Extended help

The factors come from [`cMicrobialEfficiencycLit`](@ref),
[`cMicrobialEfficiencycMic`](@ref) and [`cMicrobialEfficiencycSoil`](@ref), each with its
own `_none`, `_constant`, `_texture` and `_CASA` approaches, so the treatment of one pool
group can be swapped without touching the other two.

Combining is valid because the three own disjoint giver pools: a factor writes an
efficiency over the outgoing transfers of the pools it owns and leaves every other
transfer at one. The vegetation transfers no factor owns keep the neutral one that
`cCycleBase` allocated, which is right, since litterfall is not microbial decomposition.

All three factor processes must be selected in the model structure alongside this
approach; a missing one is an absent diagnostic rather than a neutral factor, so it fails
at unpack rather than silently leaving that group's transfers at perfect retention.
Leaving `cMicrobialEfficiency` out entirely instead gives every flow the efficiency of
one that `cCycleBase` allocates.

To reproduce the whole-vector texture response this process used to offer in one
approach, select `_texture` in all three groups. To reproduce the CASA table, select
`_CASA` in all three.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cMicrobialEfficiency_mult
