export cQualityPartitionMetabolicFraction_PFT

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartitionMetabolicFraction_PFT{T1} <: cQualityPartitionMetabolicFraction
    frac_metabolic_per_PFT::T1 = Float64.([0.5303, 0.4504, 0.2786, 0.0508, 0.4504, 0.5503, 0.6502, 0.85, 0.3305, 0.5503, 0.5503, 0.6902]) | (0.0, 1.0) | "fraction of leaf and fine-root litterfall routed to the metabolic litter pools, per PFT class" | "fraction" | ""
end
#! format: on

function define(params::cQualityPartitionMetabolicFraction_PFT, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_metabolic_fraction = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_metabolic_fraction ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitionMetabolicFraction_PFT, forcing, land, helpers)
    ## unpack parameters
    @unpack_cQualityPartitionMetabolicFraction_PFT params

    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_metabolic_fraction ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
        PFT ⇐ land.states
        o_one ⇐ land.constants
    end

    ## calculate variables
    # PFT is a one-based class index, so it is clamped to the length of the per-PFT
    # vector rather than trusted blindly, as in metabolicFraction_CASA.
    ipft = clamp(round(Int, PFT), 1, length(frac_metabolic_per_PFT))
    frac_metabolic = frac_metabolic_per_PFT[ipft]

    for (metabolic_edge, structural_edge) ∈ QP_METABOLIC_FRACTION_GROUPS
        c_flow_QP_f_metabolic_fraction = setQPGroup(c_flow_QP_f_metabolic_fraction,
            c_flow_named_edges, (metabolic_edge, structural_edge),
            (frac_metabolic, o_one - frac_metabolic))
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_metabolic_fraction ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitionMetabolicFraction_PFT}) = "Metabolic litter fraction of the carbon-quality partition looked up per PFT class."

@doc """

	$(getModelDocString(cQualityPartitionMetabolicFraction_PFT))

---

# Extended help

The approach selects `frac_metabolic_per_PFT` for the PFT class in
`land.states.PFT` and writes it, with its complement, into the flows of
`QP_METABOLIC_FRACTION_GROUPS`.

The defaults are the CASA relation
`clamp_zero_one(0.85 - 0.018 * lit_C_to_N * lit_frac_lignin * 2.22)` evaluated
over the per-PFT litter chemistry of
[`metabolicFraction_CASA`](@ref), so this approach starts from the values CASA
produces while leaving them free to be calibrated on their own. PFT class 8 has
no lignin in that chemistry and therefore keeps the intercept, 0.85.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cQualityPartitionMetabolicFraction_PFT
