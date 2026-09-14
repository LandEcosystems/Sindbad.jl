export cQualityPartitioncVeg_equal

struct cQualityPartitioncVeg_equal <: cQualityPartitioncVeg end

function define(params::cQualityPartitioncVeg_equal, forcing, land, helpers)
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

function precompute(params::cQualityPartitioncVeg_equal, forcing, land, helpers)
    @unpack_nt begin
        (c_flow_order, c_giver, c_taker) ⇐ land.cCycleBase
        c_flow_QP_f_cVeg ⇐ land.diagnostics
    end

    c_flow_QP_f_cVeg = getQPEqual(c_flow_QP_f_cVeg, c_flow_order, c_giver, c_taker, helpers.pools.zix.cVeg)

    @pack_nt c_flow_QP_f_cVeg ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitioncVeg_equal}) = "."

@doc """

	$(getModelDocString(cQualityPartitioncVeg_equal))

---

# Extended help

Note that this is an equal split, not a factor of one. A giver whose outgoing
flows are all owned by this process must still divide its carbon among them, or
it would give away more than it has once the factors are multiplied. On a
structure with only one of the two pathways present the split degenerates to one,
which is the neutral value.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: as cQualityPartitionMetabolicFraction_equal
 - 2.0 on 10.09.2026 [skoirala]: renamed/relocated into cQualityPartitioncVeg

*Created by*
 - skoirala

"""
cQualityPartitioncVeg_equal
