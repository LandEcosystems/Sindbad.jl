export cQualityPartition_none


struct cQualityPartition_none <: cQualityPartition end

function define(params::cQualityPartition_none, forcing, land, helpers)
    @unpack_nt begin
        (c_flow_order, c_taker, c_giver) ⇐ land.constants
        cEco ⇐ land.pools
    end

    # Instantiate a full partition vector, making sure that the givers do not given more that what they have (sum of columns == 1)
    c_flow_QP_vec = one.(eltype(cEco).(zero([c_taker...])))

    if cEco isa SVector
        c_flow_QP_vec = SVector{length(c_flow_QP_vec)}(c_flow_QP_vec)
    end

    for fO ∈ c_flow_order
        give_r = c_giver[fO]

        # Count only active flows belonging to the current carbon-flow topology.
        n_out = count(fO_i -> c_giver[fO_i] == give_r, c_flow_order)

        # No preferential quality partitioning: equally divide the giver's
        # available carbon among its active outgoing pathways.
        frac_out = safe_divide(one.(c_flow_QP_vec[fO]), n_out)
        c_flow_QP_vec = repElem(c_flow_QP_vec, frac_out, c_flow_QP_vec, c_flow_QP_vec, fO)
    end

    @pack_nt c_flow_QP_vec ⇒ land.diagnostics
	return land
end

purpose(::Type{cQualityPartition_none}) = "Use a neutral carbon-quality partition: c_flow_QP_vec is one for every active carbon transfer, so the existing carbon-flow partition is left unchanged."

@doc """ 

	$(getModelDocString(cQualityPartition_none))

---

# Extended help

This approach is the identity element for carbon-quality partitioning. It does
not introduce an additional labile/recalcitrant split and therefore sets every
entry of `c_flow_QP_vec` to one.

*Versions*
 - 1.0 on 27.08.2026 [sol]

*Created by*
 - sol

"""
cQualityPartition_none

