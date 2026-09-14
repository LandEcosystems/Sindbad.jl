export cQualityPartitioncVeg_vegQualityTraits

struct cQualityPartitioncVeg_vegQualityTraits <: cQualityPartitioncVeg end

function define(params::cQualityPartitioncVeg_vegQualityTraits, forcing, land, helpers)
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

function precompute(params::cQualityPartitioncVeg_vegQualityTraits, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_cVeg ⇐ land.diagnostics
        c_flow_qp_groups ⇐ land.cCycleBase
        lit_frac_metabolic ⇐ land.properties
        o_one ⇐ land.constants
    end

    c_flow_QP_f_cVeg = getQP(c_flow_QP_f_cVeg, c_flow_order, c_giver, c_taker, helpers.pools.zix.cVeg, 
        c_flow_taker_turnover_rank, o_one - lit_frac_metabolic)

    ## pack land variables
    @pack_nt c_flow_QP_f_cVeg ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitioncVeg_vegQualityTraits}) = "Metabolic litter fraction of the carbon-quality partition, read directly from vegQualityTraits so the partition always matches the litter chemistry actually in use."

@doc """

	$(getModelDocString(cQualityPartitioncVeg_vegQualityTraits))

---

# Extended help

Reads `lit_frac_metabolic` from `land.properties`, published by whichever
`vegQualityTraits` approach is selected, and writes it with its complement into
the flows of `land.cCycleBase.c_flow_qp_groups.cVeg`. No parameters of its own:
the litter chemistry is declared exactly once, in `vegQualityTraits`.

This is the properly-connected replacement for a former per-PFT-table approach
that never read `vegQualityTraits`' actual output and could silently disagree
with it.

*References*

*Versions*
 - 1.0 on 10.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cQualityPartitioncVeg_vegQualityTraits
