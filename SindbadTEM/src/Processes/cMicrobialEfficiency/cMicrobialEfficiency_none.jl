export cMicrobialEfficiency_none

struct cMicrobialEfficiency_none <: cMicrobialEfficiency end

function precompute(params::cMicrobialEfficiency_none, forcing, land, helpers)
    # Nothing to do: cCycleBase allocates c_flow_ME_vec neutral, one per flow, and this
    # approach is the statement that no microbial efficiency control applies. The three
    # pool-group factors are deliberately not read, so this holds whether or not they
    # are selected.
    return land
end

purpose(::Type{cMicrobialEfficiency_none}) = "Applies no microbial carbon-transfer efficiency: every transfer keeps the neutral efficiency of one, so decomposing carbon is retained in full by the receiving pool."

@doc """

	$(getModelDocString(cMicrobialEfficiency_none))

---

# Extended help

A factor of one means perfect retention, not zero retention: carbon leaving a pool all
arrives, and none of it respires through the microbial-efficiency pathway. `_none` means
the same thing here as it does in [`cMicrobialEfficiencycLit_none`](@ref) and its two
siblings, so the name reads the same at every level of the family.

For the opposite endpoint, where all decomposed carbon respires, select
[`cMicrobialEfficiency_constant`](@ref) with `constant_MicEff` at zero.

Selecting this is equivalent to leaving `cMicrobialEfficiency` out of the model structure
altogether, since `cCycleBase` allocates the vector neutral either way. It exists so that
the intent can be stated in the model structure rather than inferred from an absence, and
so that the three pool-group factors can stay selected while their result is ignored.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cMicrobialEfficiency_none
