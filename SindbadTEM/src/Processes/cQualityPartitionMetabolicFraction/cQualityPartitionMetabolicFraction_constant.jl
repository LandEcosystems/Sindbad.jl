export cQualityPartitionMetabolicFraction_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartitionMetabolicFraction_constant{T1} <: cQualityPartitionMetabolicFraction
    frac_metabolic::T1 = 0.85 | (0.0, 1.0) | "fraction of leaf and fine-root litterfall routed to the metabolic litter pools" | "fraction" | ""
end
#! format: on

function define(params::cQualityPartitionMetabolicFraction_constant, forcing, land, helpers)
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

function precompute(params::cQualityPartitionMetabolicFraction_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_cQualityPartitionMetabolicFraction_constant params

    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_metabolic_fraction ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
        o_one ⇐ land.constants
    end

    ## calculate variables
    for (metabolic_edge, structural_edge) ∈ QP_METABOLIC_FRACTION_GROUPS
        c_flow_QP_f_metabolic_fraction = setQPGroup(c_flow_QP_f_metabolic_fraction,
            c_flow_named_edges, (metabolic_edge, structural_edge),
            (frac_metabolic, o_one - frac_metabolic))
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_metabolic_fraction ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitionMetabolicFraction_constant}) = "Sets the metabolic litter fraction of the carbon-quality partition to a uniform constant."

@doc """

	$(getModelDocString(cQualityPartitionMetabolicFraction_constant))

---

# Extended help

Use this approach to hold the metabolic/structural split of leaf and fine-root
litterfall at a prescribed value instead of varying it with PFT class. The
default of 0.85 is the CASA intercept, which
[`metabolicFraction_CASA`](@ref) returns when litter contains no lignin.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cQualityPartitionMetabolicFraction_constant
