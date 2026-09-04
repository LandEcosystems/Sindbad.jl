export cQualityPartitionLignin_none

struct cQualityPartitionLignin_none <: cQualityPartitionLignin end

function define(params::cQualityPartitionLignin_none, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_lignin = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_lignin ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitionLignin_none, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_lignin ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
    end

    ## calculate variables
    # No lignin preference between direct stabilization and the microbial pathway,
    # but still a partition: structural and woody litter decomposition divides
    # equally over whichever of the two the configured structure has.
    for group ∈ (QP_LIGNIN_STRUCT_GROUPS..., QP_LIGNIN_WOOD_GROUPS...)
        c_flow_QP_f_lignin = setQPGroupEqual(c_flow_QP_f_lignin, c_flow_named_edges, group)
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_lignin ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitionLignin_none}) = "Applies no lignin preference: structural and woody litter decomposition divides equally between the slow soil pool and the microbial pools."

@doc """

	$(getModelDocString(cQualityPartitionLignin_none))

---

# Extended help

Note that this is an equal split, not a factor of one. A giver whose outgoing
flows are all owned by this process must still divide its carbon among them, or
it would give away more than it has once the factors are multiplied. On a
structure with only one of the two pathways present the split degenerates to one,
which is the neutral value.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cQualityPartitionLignin_none
