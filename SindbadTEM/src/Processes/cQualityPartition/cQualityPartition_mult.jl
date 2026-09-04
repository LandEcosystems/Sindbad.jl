export cQualityPartition_mult

struct cQualityPartition_mult <: cQualityPartition end

function precompute(params::cQualityPartition_mult, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_metabolic_fraction ⇐ land.diagnostics
        c_flow_QP_f_lignin ⇐ land.diagnostics
        c_flow_QP_f_soil_props ⇐ land.diagnostics
        c_flow_QP_vec ⇐ land.diagnostics
    end

    ## calculate variables
    # Each factor is one on every flow it does not own, and the three own disjoint
    # giver pools, so the product of the factors is the partition itself. There is
    # no base term to multiply onto, unlike c_eco_k_base in cTau_mult.
    for i ∈ eachindex(c_flow_QP_vec)
        tmp = c_flow_QP_f_metabolic_fraction[i] * c_flow_QP_f_lignin[i] * c_flow_QP_f_soil_props[i]
        c_flow_QP_vec = repElem(c_flow_QP_vec, tmp, c_flow_QP_vec, c_flow_QP_vec, i)
    end

    ## pack land variables
    @pack_nt c_flow_QP_vec ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartition_mult}) = "Combines the metabolic-fraction, lignin, and soil-property controls of the carbon-quality partition by multiplication."

@doc """

	$(getModelDocString(cQualityPartition_mult))

---

# Extended help

This is the composed counterpart of [`cQualityPartition_CASA`](@ref), which
declares the same partition as one table. The factors come from
[`cQualityPartitionMetabolicFraction`](@ref),
[`cQualityPartitionLignin`](@ref) and [`cQualityPartitionSoilProperties`](@ref), and
each has its own `_none`, `_constant` and PFT- or clay-driven approaches, so one
control can be swapped or disabled without touching the other two.

Multiplication is valid because the three factors own disjoint giver pools: a
factor writes a partition over the outgoing flows of the givers it owns and
leaves every other flow at one. The flows no factor owns, such as
`cVegWood_to_cLitWood` or `cSoilOld_to_cMicSoil`, are single-outflow and keep the
neutral one that `cCycleBase` allocated.

All three factor processes must be selected in the model structure alongside this
approach; a missing one is an absent diagnostic rather than a neutral factor.
Leaving `cQualityPartition` out entirely instead gives every flow the partition
of one that `cCycleBase` allocates.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cQualityPartition_mult
