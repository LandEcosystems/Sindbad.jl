export cQualityPartition_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartition_CASA{T1,T2,T3,T4,T5} <: cQualityPartition
    frac_lignin_wood::T1 = 0.4 | (0.0, 1.0) | "Fraction of wood-derived slow litter associated with the lignin-controlled recalcitrant pathway." | "fraction" | ""
    frac_clay_cSoilSlow_A::T2 = 0.003 | (0.0, 1.0) | "Intercept of the clay-dependent fraction of slow-soil decomposition partitioned to old soil carbon." | "fraction" | ""
    frac_clay_cSoilSlow_B::T3 = 0.009 | (0.0, Inf) | "Sensitivity of the slow-soil to old-soil partition fraction to clay content." | "fraction" | ""
    frac_clay_cMicSoil_A::T4 = 0.003 | (-Inf, Inf) | "" | "" | ""
    frac_clay_cMicSoil_B::T5 = 0.032 | (-Inf, Inf) | "" | "" | ""

end
#! format: on

function define(params::cQualityPartition_CASA, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.constants
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

function fill_QP_matrix!(M, flows, land, helpers)
    for (; giver, taker, value) in flows
        i_give = pool_index(giver, land, helpers)
        i_take = pool_index(taker, land, helpers)
        M[i_take, i_give] = value
        # to revamp: we should give some warning if we are filling a value that is empty in A (the links matrix)
        # or if we are filling a value that already has a value in QP...
    end
    return M
end

function precompute(params::cQualityPartition_CASA, forcing, land, helpers)
    @unpack_cQualityPartition_CASA params
    @unpack_nt begin
        c_flow_QP_vec ⇐ land.diagnostics
        (c_flow_order, c_giver, c_taker) ⇐ land.constants
        st_clay ⇐ land.properties
    end
    # Matrix of flows
    QP_flows = [
        (giver = :cSoilSlow,   taker = :cMicSoil,     value = 1-(frac_clay_cSoilSlow_A+(frac_clay_cSoilSlow_B*st_clay))),
        (giver = :cSoilSlow,   taker = :cSoilOld,     value = frac_clay_cSoilSlow_A+(frac_clay_cSoilSlow_B*st_clay)),
        (giver = :cMicSoil,    taker = :cSoilSlow,    value = 1-(frac_clay_cMicSoil_A+(frac_clay_cMicSoil_B*st_clay))),
        (giver = :cMicSoil,    taker = :cSoilOld,     value = frac_clay_cMicSoil_A+(frac_clay_cMicSoil_B*st_clay)),
        (giver = :cVegLeaf,    taker = :cLitLeafM,    value = MTF),
        (giver = :cVegLeaf,    taker = :cLitLeafS,    value = 1 - MTF),
        (giver = :cVegWood,    taker = :cLitWood,     value = 1),
        (giver = :cVegRootF,   taker = :cLitRootFM,   value = MTF),
        (giver = :cVegRootF,   taker = :cLitRootFS,   value = 1 - MTF),
        (giver = :cVegRootC,   taker = :cLitRootC,    value = 1),
        (giver = :cLitLeafS,   taker = :cSoilSlow,    value = SCLIGNIN),
        (giver = :cLitLeafS,   taker = :cMicSurf,     value = 1 - SCLIGNIN),
        (giver = :cLitRootFS,  taker = :cSoilSlow,    value = SCLIGNIN),
        (giver = :cLitRootFS,  taker = :cMicSoil,     value = 1 - SCLIGNIN),
        (giver = :cLitWood,    taker = :cSoilSlow,    value = frac_lignin_wood),
        (giver = :cLitWood,    taker = :cMicSurf,     value = 1 - frac_lignin_wood),
        (giver = :cLitRootC,   taker = :cSoilSlow,    value = frac_lignin_wood),
        (giver = :cLitRootC,   taker = :cMicSoil,     value = 1 - frac_lignin_wood),
        (giver = :cSoilOld,    taker = :cMicSoil,     value = 1),
        (giver = :cLitLeafM,   taker = :cMicSurf,     value = 1),
        (giver = :cLitRootFM,  taker = :cMicSoil,     value = 1),
        (giver = :cMicSurf,    taker = :cSoilSlow,    value = 1),
    ]

    # revamp: there should be some warning if the c_flow_QP_vec is not the same size as the QP_flows

    # fill the matrix
    c_flow_QP_array = fill_transfer_matrix!(c_flow_QP_array, flows, land, helpers)


    @pack_nt (c_flow_QP_array, c_flow_QP_vec) ⇒ land.diagnostics
	return land
end

purpose(::Type{cQualityPartition_CASA}) = "Represent CASA-style carbon-quality partitioning on the GSI carbon-pool topology using wood-lignin control of slow-litter transfer and clay control of slow-soil stabilization."

@doc """ 

	$(getModelDocString(cQualityPartition_CASA))

---
# Extended help

This approach refactors the partitioning term (`p_F_vec`) formerly distributed
across `cFlowVegProperties_CASA` and `cFlowSoilProperties_CASA` into the
dedicated `cQualityPartition` process. The
output `c_flow_QP_vec` is indexed by active flow (`c_flow_order`) rather than by a
dense giver-taker matrix.

The original CASA pool structure contains explicit metabolic/structural litter
and microbial pools. The GSI carbon-cycle structure is more aggregated, so the
lignin-controlled CASA partition is represented here by the available
`cLitSlow -> cSoilSlow` transfer. The clay-dependent CASA partition of
`cSoilSlow` decomposition is also retained on the available
`cSoilSlow -> cSoilOld` edge. The complementary microbial branches are absent
from GSI, so these mappings are effective representations rather than a
one-to-one reproduction of the full CASA topology.

*References*
 - Carvalhais, N., Reichstein, M., Seixas, J., Collatz, G. J., Pereira, J. S., Berbigier, P., & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for biogeochemical modeling performance and inverse parameter retrieval. Global Biogeochemical Cycles, 22(2).
 - Potter, C. S., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003). Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data and ecosystem modeling 1982-1998. Global and Planetary Change, 39(3-4), 201-213.
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 27.08.2026 [sol]

*Created by*
 - sol

"""
cQualityPartition_CASA
