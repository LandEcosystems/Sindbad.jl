export cQualityPartitioncVeg_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartitioncVeg_constant{T1} <: cQualityPartitioncVeg
    frac_metabolic::T1 = 0.85 | (0.0, 1.0) | "fraction of leaf and fine-root litterfall routed to the metabolic litter pools" | "fraction" | ""
end
#! format: on

function define(params::cQualityPartitioncVeg_constant, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_cVeg = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_cVeg ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitioncVeg_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_cQualityPartitioncVeg_constant params

    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_cVeg ⇐ land.diagnostics
        c_flow_qp_groups ⇐ land.cCycleBase
        o_one ⇐ land.constants
    end

    ## calculate variables
    for (fast_positions, slow_positions) ∈ c_flow_qp_groups.cVeg
        for i ∈ fast_positions
            c_flow_QP_f_cVeg = repElem(c_flow_QP_f_cVeg, frac_metabolic, i)
        end
        for i ∈ slow_positions
            c_flow_QP_f_cVeg = repElem(c_flow_QP_f_cVeg, o_one - frac_metabolic, i)
        end
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_cVeg ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitioncVeg_constant}) = "Sets the metabolic litter fraction of the carbon-quality partition to a uniform constant."

@doc """

	$(getModelDocString(cQualityPartitioncVeg_constant))

---

# Extended help

Use this approach to hold the metabolic/structural split of leaf and fine-root
litterfall at a prescribed value instead of reading it from `vegQualityTraits` or
varying it with PFT class. The default of 0.85 is the CASA intercept, which
[`vegQualityTraits_vegType`](@ref) returns when litter contains no lignin.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: as cQualityPartitionMetabolicFraction_constant
 - 2.0 on 10.09.2026 [skoirala]: renamed/relocated into cQualityPartitioncVeg

*Created by*
 - skoirala

"""
cQualityPartitioncVeg_constant
