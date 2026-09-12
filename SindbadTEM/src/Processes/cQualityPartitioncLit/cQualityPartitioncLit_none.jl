export cQualityPartitioncLit_none

struct cQualityPartitioncLit_none <: cQualityPartitioncLit end

function define(params::cQualityPartitioncLit_none, forcing, land, helpers)
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

function precompute(params::cQualityPartitioncLit_none, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_cLit ⇐ land.diagnostics
        c_flow_qp_groups ⇐ land.cCycleBase
    end

    ## calculate variables
    # No lignin preference between direct stabilization and the microbial pathway,
    # but still a partition: structural and woody litter decomposition divides
    # equally over whichever of the two the configured structure has.
    for (soil_positions, mic_positions) ∈ (c_flow_qp_groups.cLit.structural..., c_flow_qp_groups.cLit.wood...)
        n_out = length(soil_positions) + length(mic_positions)
        n_out == 0 && continue
        frac_out = safe_divide(one(eltype(c_flow_QP_f_cLit)), n_out)
        for i ∈ (soil_positions..., mic_positions...)
            c_flow_QP_f_cLit = repElem(c_flow_QP_f_cLit, frac_out, i)
        end
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_cLit ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitioncLit_none}) = "Applies no lignin preference: structural and woody litter decomposition divides equally between the slow soil pool and the microbial pools."

@doc """

	$(getModelDocString(cQualityPartitioncLit_none))

---

# Extended help

Note that this is an equal split, not a factor of one. A giver whose outgoing
flows are all owned by this process must still divide its carbon among them, or
it would give away more than it has once the factors are multiplied. On a
structure with only one of the two pathways present the split degenerates to one,
which is the neutral value.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: as cQualityPartitionLignin_none
 - 2.0 on 10.09.2026 [skoirala]: renamed/relocated into cQualityPartitioncLit

*Created by*
 - skoirala

"""
cQualityPartitioncLit_none
