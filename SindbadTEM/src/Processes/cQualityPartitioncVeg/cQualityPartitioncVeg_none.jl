export cQualityPartitioncVeg_none

struct cQualityPartitioncVeg_none <: cQualityPartitioncVeg end

function define(params::cQualityPartitioncVeg_none, forcing, land, helpers)
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

function precompute(params::cQualityPartitioncVeg_none, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_cVeg ⇐ land.diagnostics
        c_flow_qp_groups ⇐ land.cCycleBase
    end

    ## calculate variables
    # No preference between the metabolic and structural pathway, but still a
    # partition: leaf and fine-root litterfall divides equally over whichever of
    # the two the configured structure has.
    for (fast_positions, slow_positions) ∈ c_flow_qp_groups.cVeg
        n_out = length(fast_positions) + length(slow_positions)
        n_out == 0 && continue
        frac_out = safe_divide(one(eltype(c_flow_QP_f_cVeg)), n_out)
        for i ∈ (fast_positions..., slow_positions...)
            c_flow_QP_f_cVeg = repElem(c_flow_QP_f_cVeg, frac_out, i)
        end
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_cVeg ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitioncVeg_none}) = "Applies no metabolic-fraction preference: leaf and fine-root litterfall divides equally over the metabolic and structural litter pools."

@doc """

	$(getModelDocString(cQualityPartitioncVeg_none))

---

# Extended help

Note that this is an equal split, not a factor of one. A giver whose outgoing
flows are all owned by this process must still divide its carbon among them, or
it would give away more than it has once the factors are multiplied. On a
structure with only one of the two pathways present the split degenerates to one,
which is the neutral value.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: as cQualityPartitionMetabolicFraction_none
 - 2.0 on 10.09.2026 [skoirala]: renamed/relocated into cQualityPartitioncVeg

*Created by*
 - skoirala

"""
cQualityPartitioncVeg_none
