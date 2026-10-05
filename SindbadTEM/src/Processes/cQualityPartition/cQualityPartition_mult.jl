export cQualityPartition_mult

struct cQualityPartition_mult <: cQualityPartition end

function precompute(params::cQualityPartition_mult, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_cVeg ⇐ land.diagnostics
        c_flow_QP_f_cLit ⇐ land.diagnostics
        c_flow_QP_f_cMic ⇐ land.diagnostics
        c_flow_QP_f_cSoil ⇐ land.diagnostics
        c_flow_QP_vec ⇐ land.diagnostics
    end

    ## calculate variables
    # Each factor is one on every flow it does not own, and the four own disjoint
    # giver pools, so the product of the factors is the partition itself. There is
    # no base term to multiply onto, unlike c_eco_k_base in cTau_mult.
    for i ∈ eachindex(c_flow_QP_vec)
        tmp = c_flow_QP_f_cVeg[i] * c_flow_QP_f_cLit[i] * c_flow_QP_f_cMic[i] * c_flow_QP_f_cSoil[i]
        c_flow_QP_vec = repElem(c_flow_QP_vec, tmp, i)
    end

    ## pack land variables
    @pack_nt c_flow_QP_vec ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartition_mult}) = "Combines the cVeg, cLit, cMic, and cSoil giver-group controls of the carbon-quality partition by multiplication."

@doc """

	$(getModelDocString(cQualityPartition_mult))

---

# Extended help

The factors come from [`cQualityPartitioncVeg`](@ref), [`cQualityPartitioncLit`](@ref),
[`cQualityPartitioncMic`](@ref) and [`cQualityPartitioncSoil`](@ref), each named
after the giver pool group it owns, the way `cMicrobialEfficiency`'s factors are.
Each has its own `_none`, `_constant` and a properly-connected or PFT/clay-driven
approach, so one control can be swapped or disabled without touching the others.
Selecting `cQualityPartitioncVeg_vegQualityTraits`,
`cQualityPartitioncLit_vegQualityTraits`, `cQualityPartitioncMic_texture` and
`cQualityPartitioncSoil_texture` together reproduces the CASA table exactly, which
used to require the separate self-contained `cQualityPartition_CASA` approach
(now removed, since this composition reproduces it exactly).

Multiplication is valid because the four factors own disjoint giver pools: a
factor writes a partition over the outgoing flows of the givers it owns and
leaves every other flow at one. The flows no factor owns, such as
`cVegWood_to_cLitWood` or `cSoilOld_to_cMicSoil`, are single-outflow and keep the
neutral one that `cCycleBase` allocated.

All four factor processes must be selected in the model structure alongside this
approach; a missing one is an absent diagnostic rather than a neutral factor.
Leaving `cQualityPartition` out entirely instead gives every flow the partition
of one that `cCycleBase` allocates.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]
 - 2.0 on 10.09.2026 [skoirala]: reorganized around the four cQualityPartitionc{Veg,Lit,Mic,Soil} giver-group factors, replacing cQualityPartitionMetabolicFraction/Lignin/SoilProperties

*Created by*
 - skoirala

"""
cQualityPartition_mult
