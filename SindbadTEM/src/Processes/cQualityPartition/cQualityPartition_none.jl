export cQualityPartition_none


struct cQualityPartition_none <: cQualityPartition end

function precompute(params::cQualityPartition_none, forcing, land, helpers)
    @unpack_nt begin
        (c_flow_order, c_giver) ⇐ land.cCycleBase
        c_flow_QP_vec ⇐ land.diagnostics
    end

    # The neutral vector comes from cCycleBase; here it is turned into a partition
    # that makes sure the givers do not give more than what they have (sum of
    # columns == 1)
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

purpose(::Type{cQualityPartition_none}) = "Use a neutral carbon-quality partition: every giver divides its carbon equally among its active outgoing transfers, with no preference for any pathway."

@doc """ 

	$(getModelDocString(cQualityPartition_none))

---

# Extended help

This approach introduces no labile/recalcitrant preference: each giver splits its
carbon equally over its active outgoing flows, so a giver with a single outgoing
flow keeps the neutral partition of one and a giver with several conserves mass
across them.

The vector itself is allocated neutral by `cCycleBase`, so leaving
`cQualityPartition` out of the model structure entirely gives every flow a
partition of one. That differs from selecting this approach, which still splits
multi-outflow givers.

*Versions*
 - 1.0 on 27.08.2026 [sol]
 - 1.1 on 04.09.2026 [skoirala]: c_flow_QP_vec allocated by cCycleBase; split moved to precompute

*Created by*
 - sol

"""
cQualityPartition_none

