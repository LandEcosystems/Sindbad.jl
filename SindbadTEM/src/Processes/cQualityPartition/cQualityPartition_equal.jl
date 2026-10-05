export cQualityPartition_equal


struct cQualityPartition_equal <: cQualityPartition end

function precompute(params::cQualityPartition_equal, forcing, land, helpers)
    @unpack_nt begin
        (c_flow_order, c_giver, c_taker) ⇐ land.cCycleBase
        c_flow_QP_vec ⇐ land.diagnostics
    end

    c_flow_QP_vec = getQPEqual(c_flow_QP_vec, c_flow_order, c_giver, c_taker, helpers.pools.zix.cVeg)
    c_flow_QP_vec = getQPEqual(c_flow_QP_vec, c_flow_order, c_giver, c_taker, helpers.pools.zix.cLit)
    c_flow_QP_vec = getQPEqual(c_flow_QP_vec, c_flow_order, c_giver, c_taker, helpers.pools.zix.cSoil)
    c_flow_QP_vec = getQPEqual(c_flow_QP_vec, c_flow_order, c_giver, c_taker, helpers.pools.zix.cMic)

    @pack_nt c_flow_QP_vec ⇒ land.diagnostics
	return land
end

purpose(::Type{cQualityPartition_equal}) = "Use a neutral carbon-quality partition: every giver divides its carbon equally among its active outgoing transfers to non-vegetation pools, with no preference for any pathway."

@doc """ 

	$(getModelDocString(cQualityPartition_equal))

---

# Extended help

This approach introduces no labile/recalcitrant preference: each giver splits its
carbon equally over its active outgoing flows to non-vegetation pools. Flows whose
taker is a vegetation pool are not modified by quality partitioning. A giver with a
single non-vegetation outgoing flow keeps the neutral partition of one, while a
giver with several non-vegetation outgoing flows conserves mass across them.

The vector itself is allocated neutral by `cCycleBase`, so leaving
`cQualityPartition` out of the model structure entirely gives every flow a
partition of one. That differs from selecting this approach, which still splits
multi-outflow givers.

*Versions*
 - 1.0 on 27.08.2026 [sol]
 - 1.1 on 04.09.2026 [skoirala]: c_flow_QP_vec allocated by cCycleBase; split moved to precompute
 - 1.2 on 14.09.2026 [s&s]: TO SIMPLIFY - simplify and tidy up

*Created by*
 - sol

"""
cQualityPartition_equal

