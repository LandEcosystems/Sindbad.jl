export cQualityPartitioncLit_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartitioncLit_constant{T1,T2} <: cQualityPartitioncLit
    frac_lignin_struct::T1 = 0.3 | (0.0, 1.0) | "lignin as a fraction of structural litter carbon" | "fraction" | ""
    frac_lignin_wood::T2 = 0.4 | (0.0, 1.0) | "lignin fraction of woody litter" | "fraction" | ""
end
#! format: on

function define(params::cQualityPartitioncLit_constant, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_cLit = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_cLit ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitioncLit_constant, forcing, land, helpers)
    @unpack_cQualityPartitioncLit_constant params

    @unpack_nt begin
        (c_flow_QP_f_cLit, c_eco_k_base, k_hilo_lit_split) ⇐ land.diagnostics
        (c_flow_order, c_giver, c_taker, c_flow_taker_turnover_rank) ⇐ land.cCycleBase
        o_one ⇐ land.constants
    end

    c_flow_QP_f_cLit = getQP(c_flow_QP_f_cLit, c_flow_order, c_giver, c_taker, helpers.pools.zix.cLit, 
        c_flow_taker_turnover_rank, frac_lignin_wood, frac_lignin_struct, k_hilo_lit_split, c_eco_k_base)

    @pack_nt c_flow_QP_f_cLit ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitioncLit_constant}) = "Sets the lignin control of the carbon-quality partition to uniform constants for structural and woody litter."

@doc """

	$(getModelDocString(cQualityPartitioncLit_constant))

---

# Extended help

Use this approach to prescribe the two lignin fractions directly instead of
reading them from `vegQualityTraits` or varying them with PFT class. The defaults
are those of `vegQualityTraits_constant`'s lignin fields.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: as cQualityPartitionLignin_constant
 - 2.0 on 10.09.2026 [skoirala]: renamed/relocated into cQualityPartitioncLit

*Created by*
 - skoirala

"""
cQualityPartitioncLit_constant
