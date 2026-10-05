export cQualityPartitioncSoil_equal

struct cQualityPartitioncSoil_equal <: cQualityPartitioncSoil end

function define(params::cQualityPartitioncSoil_equal, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_cSoil = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_cSoil ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitioncSoil_equal, forcing, land, helpers)
    @unpack_nt begin
        (c_flow_order, c_giver, c_taker) ⇐ land.cCycleBase
        c_flow_QP_f_cSoil ⇐ land.diagnostics
    end

    c_flow_QP_f_cSoil = getQPEqual(c_flow_QP_f_cSoil, c_flow_order, c_giver, c_taker, helpers.pools.zix.cSoil)

    @pack_nt c_flow_QP_f_cSoil ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitioncSoil_equal}) = "."

@doc """

	$(getModelDocString(cQualityPartitioncSoil_equal))

---

# Extended help

Note that this is an equal split, not a factor of one. A giver whose outgoing
flows are all owned by this process must still divide its carbon among them, or
it would give away more than it has once the factors are multiplied. On a
structure with only one outflow present, such as GSI where `cSoilSlow` feeds only
`cSoilOld`, the split degenerates to one, which is the neutral value.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: as the cSoilSlow half of cQualityPartitionSoilProperties_equal
 - 2.0 on 10.09.2026 [skoirala]: split off into its own cQualityPartitioncSoil factor

*Created by*
 - skoirala

"""
cQualityPartitioncSoil_equal
