export cQualityPartition_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartition_CASA{T1,T2,T3,T4} <: cQualityPartition
    frac_clay_cSoilSlow_A::T1 = 0.003 | (0.0, 1.0) | "Intercept of the clay-dependent fraction of slow-soil decomposition partitioned to old soil carbon." | "fraction" | ""
    frac_clay_cSoilSlow_B::T2 = 0.009 | (0.0, Inf) | "Sensitivity of the slow-soil to old-soil partition fraction to clay content." | "fraction" | ""
    frac_clay_cMicSoil_A::T3 = 0.003 | (0.0, 1.0) | "Intercept of the clay-dependent fraction of soil-microbial decomposition partitioned to old soil carbon." | "fraction" | ""
    frac_clay_cMicSoil_B::T4 = 0.032 | (0.0, Inf) | "Sensitivity of the soil-microbial to old-soil partition fraction to clay content." | "fraction" | ""
end
#! format: on

function define(params::cQualityPartition_CASA, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    ## Instantiate c_flow_QP_vec with the neutral value (one) for every active flow.
    ##
    ## The vector has one element per active carbon transfer, in exactly the same
    ## order as c_flow_order/c_giver/c_taker. This follows the flow-vector design
    ## used by cFlow_GSI and avoids constructing a dense pool-by-pool matrix.
    c_flow_QP_vec = getVectorOfType(cEco, length(c_taker), one)

    ## The partition vector is consumed by other carbon-cycle processes, so it is
    ## a shared diagnostic rather than a cQualityPartition-private variable.
    @pack_nt c_flow_QP_vec ⇒ land.diagnostics
	return land
end

"""
    setQPFlow(c_flow_QP_vec, c_flow_named_edges, edge, value)

Write `value` into every flow-vector position that carries the named `edge`, and
return the vector unchanged when the configured pool structure has no such edge.

The CASA partition is declared over the full CASA pool topology, but the same
approach is selected against more aggregated structures that lack the explicit
metabolic/structural litter and microbial pools. Skipping absent edges lets one
declaration serve both, instead of erroring on a pool the structure never had.
"""
function setQPFlow(c_flow_QP_vec, c_flow_named_edges, edge, value)
    hasproperty(c_flow_named_edges, edge) || return c_flow_QP_vec
    for flow ∈ getproperty(c_flow_named_edges, edge)
        c_flow_QP_vec = repElem(c_flow_QP_vec, value, c_flow_QP_vec, c_flow_QP_vec, flow)
    end
    return c_flow_QP_vec
end

function precompute(params::cQualityPartition_CASA, forcing, land, helpers)
    @unpack_cQualityPartition_CASA params
    @unpack_nt begin
        c_flow_QP_vec ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
        (lit_frac_lignin_struct, lit_frac_lignin_wood, lit_frac_metabolic, st_clay) ⇐ land.properties
        o_one ⇐ land.constants
    end

    # Collapse the soil profile to a single mean clay fraction, as in
    # cMicrobialEfficiency_texture.
    clay = mean(st_clay)
    frac_cSoilSlow_to_cSoilOld = frac_clay_cSoilSlow_A + frac_clay_cSoilSlow_B * clay
    frac_cMicSoil_to_cSoilOld = frac_clay_cMicSoil_A + frac_clay_cMicSoil_B * clay

    # Partition of every carbon transfer, keyed by giver-to-taker pool-name pair.
    # Leaf and fine-root litterfall splits by the metabolic fraction; structural
    # litter decomposition splits by the lignin fraction of structural carbon;
    # woody and coarse-root litter splits by the lignin fraction of wood; and the
    # soil pools split by clay content.
    QP_flows = (
        (:cSoilSlow_to_cMicSoil, o_one - frac_cSoilSlow_to_cSoilOld),
        (:cSoilSlow_to_cSoilOld, frac_cSoilSlow_to_cSoilOld),
        (:cMicSoil_to_cSoilSlow, o_one - frac_cMicSoil_to_cSoilOld),
        (:cMicSoil_to_cSoilOld, frac_cMicSoil_to_cSoilOld),
        (:cVegLeaf_to_cLitLeafM, lit_frac_metabolic),
        (:cVegLeaf_to_cLitLeafS, o_one - lit_frac_metabolic),
        (:cVegWood_to_cLitWood, o_one),
        (:cVegRootF_to_cLitRootFM, lit_frac_metabolic),
        (:cVegRootF_to_cLitRootFS, o_one - lit_frac_metabolic),
        (:cVegRootC_to_cLitRootC, o_one),
        (:cLitLeafS_to_cSoilSlow, lit_frac_lignin_struct),
        (:cLitLeafS_to_cMicSurf, o_one - lit_frac_lignin_struct),
        (:cLitRootFS_to_cSoilSlow, lit_frac_lignin_struct),
        (:cLitRootFS_to_cMicSoil, o_one - lit_frac_lignin_struct),
        (:cLitWood_to_cSoilSlow, lit_frac_lignin_wood),
        (:cLitWood_to_cMicSurf, o_one - lit_frac_lignin_wood),
        (:cLitRootC_to_cSoilSlow, lit_frac_lignin_wood),
        (:cLitRootC_to_cMicSoil, o_one - lit_frac_lignin_wood),
        (:cSoilOld_to_cMicSoil, o_one),
        (:cLitLeafM_to_cMicSurf, o_one),
        (:cLitRootFM_to_cMicSoil, o_one),
        (:cMicSurf_to_cSoilSlow, o_one),
    )

    for (edge, value) ∈ QP_flows
        c_flow_QP_vec = setQPFlow(c_flow_QP_vec, c_flow_named_edges, edge, value)
    end

    @pack_nt c_flow_QP_vec ⇒ land.diagnostics
	return land
end

purpose(::Type{cQualityPartition_CASA}) = "Represent CASA-style carbon-quality partitioning using the metabolic litter fraction, lignin control of structural-litter transfer, and clay control of slow-soil stabilization."

@doc """

	$(getModelDocString(cQualityPartition_CASA))

---
# Extended help

This approach refactors the partitioning term (`p_F_vec`) formerly distributed
across `cFlowVegProperties_CASA` and `cFlowSoilProperties_CASA` into the
dedicated `cQualityPartition` process. The output `c_flow_QP_vec` is indexed by
active flow (`c_flow_order`) rather than by a dense giver-taker matrix.

The litter-chemistry terms `lit_frac_metabolic`, `lit_frac_lignin_struct` and
`lit_frac_lignin_wood` come from the [`metabolicFraction`](@ref) and
[`lignin`](@ref) processes, which run before `cQualityPartition`. This approach
declares none of them itself; it previously carried a private
`frac_lignin_wood` that duplicated the one in `cFlowVegProperties_CASA`.

The flow table is declared over the full CASA pool topology and matched against
the configured structure by pool-name pair through `c_flow_named_edges`. Edges the
selected structure lacks are skipped, so on the more aggregated GSI structure the
CASA-only metabolic/structural litter and microbial edges simply do not
contribute and the remaining flows keep their neutral partition of one.

*References*
 - Carvalhais, N., Reichstein, M., Seixas, J., Collatz, G. J., Pereira, J. S., Berbigier, P., & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for biogeochemical modeling performance and inverse parameter retrieval. Global Biogeochemical Cycles, 22(2).
 - Potter, C. S., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003). Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data and ecosystem modeling 1982-1998. Global and Planetary Change, 39(3-4), 201-213.
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 27.08.2026 [sol]
 - 2.0 on 04.09.2026 [skoirala]: litter chemistry read from land.properties; flows matched by named edge

*Created by*
 - sol

"""
cQualityPartition_CASA
