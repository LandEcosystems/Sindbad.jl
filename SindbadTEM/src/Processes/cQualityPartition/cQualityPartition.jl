export cQualityPartition
export setQPFlow, setQPGroup, setQPGroupEqual

abstract type cQualityPartition <: LandEcosystem end

purpose(::Type{cQualityPartition}) = "Determine the fraction of carbon flowing between labile and recalcitrant pools."

"""
    setQPFlow(qp_vec, c_flow_named_edges, edge, value)

Write `value` into every flow-vector position that carries the named `edge`, and
return the vector unchanged when the configured pool structure has no such edge.

The partition tables are declared over the full CASA pool topology, but the same
approaches are selected against more aggregated structures that lack the explicit
metabolic/structural litter and microbial pools. Skipping absent edges lets one
declaration serve both, instead of erroring on a pool the structure never had.

The body is `setFlowEdgeValue` in `landUtils.jl`, shared with `setMEFlow`: writing a
value into the positions of a named edge is the same operation whichever per-flow
vector is being filled.
"""
function setQPFlow(qp_vec, c_flow_named_edges, edge, value)
    return setFlowEdgeValue(qp_vec, c_flow_named_edges, edge, value)
end

"""
    setQPGroup(qp_vec, c_flow_named_edges, edges, fractions)

Write one partition group: the `i`th name in `edges` gets the `i`th value in
`fractions`.

A group is the complete set of outgoing flows of one giver pool, so the fractions
of a group sum to one and the giver never gives away more than it has. Each
`cQualityPartition` factor process owns a disjoint set of givers, which is what
lets the factors be multiplied together into `c_flow_QP_vec`.
"""
function setQPGroup(qp_vec, c_flow_named_edges, edges, fractions)
    for (edge, fraction) ∈ zip(edges, fractions)
        qp_vec = setQPFlow(qp_vec, c_flow_named_edges, edge, fraction)
    end
    return qp_vec
end

"""
    setQPGroupEqual(qp_vec, c_flow_named_edges, edges)

Divide a giver's carbon equally among the flows of `edges` that the configured
pool structure actually has, and return the vector unchanged when it has none.

This is what the `_none` approach of each factor process does: no preferential
quality partitioning, but still a partition, so mass is conserved per giver
however the factors are combined. A group with only one flow present gets one,
which is the neutral value.
"""
function setQPGroupEqual(qp_vec, c_flow_named_edges, edges)
    n_out = 0
    for edge ∈ edges
        hasproperty(c_flow_named_edges, edge) || continue
        n_out += length(getproperty(c_flow_named_edges, edge))
    end
    n_out == 0 && return qp_vec
    frac_out = safe_divide(one(eltype(qp_vec)), n_out)
    for edge ∈ edges
        qp_vec = setQPFlow(qp_vec, c_flow_named_edges, edge, frac_out)
    end
    return qp_vec
end

includeApproaches(cQualityPartition, @__DIR__)

@doc """
	$(getModelDocString(cQualityPartition))

---
# Extended help

`cQualityPartition` fills in `c_flow_QP_vec`, a diagnostic vector with one entry
for every active carbon transfer defined by `c_flow_order`, `c_giver`, and
`c_taker` in the selected carbon-cycle structure. The vector itself is allocated
neutral, one per flow, by `cCycleBase`, so `cCycle` reads a valid partition even
when no `cQualityPartition` model is selected.

The process separates carbon-quality/routing effects from the transfer-rate
calculation itself. In the legacy SINDBAD CASA implementation, the corresponding
quantity was `p_F_vec`.

The partition splits along three independent controls, each of which owns a
disjoint set of givers and is a process of its own:

- [`cQualityPartitionMetabolicFraction`](@ref): the metabolic/structural split of
  leaf and fine-root litterfall.
- [`cQualityPartitionLignin`](@ref): the lignin control of structural and woody
  litter decomposition.
- [`cQualityPartitionSoilProperties`](@ref): the clay control of slow-soil and microbial
  stabilization.

[`cQualityPartition_mult`](@ref) multiplies the three factors, the way
[`cTau_mult`](@ref) multiplies the decomposition-rate stressors.
[`cQualityPartition_CASA`](@ref) remains available as a self-contained
alternative that declares all three in one table.
"""
cQualityPartition
