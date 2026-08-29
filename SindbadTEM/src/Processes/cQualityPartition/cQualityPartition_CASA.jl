export cQualityPartition_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartition_CASA{T1,T2,T3} <: cQualityPartition
    frac_lignin_wood::T1 = 0.4 | (0.0, 1.0) | "Fraction of wood-derived slow litter associated with the lignin-controlled recalcitrant pathway." | "fraction" | ""
    frac_clay_cSoilSlow_A::T2 = 0.003 | (0.0, 1.0) | "Intercept of the clay-dependent fraction of slow-soil decomposition partitioned to old soil carbon." | "fraction" | ""
    frac_clay_cSoilSlow_B::T3 = 0.009 | (0.0, Inf) | "Sensitivity of the slow-soil to old-soil partition fraction to clay content." | "fraction" | ""
end
#! format: on

function define(params::cQualityPartition_CASA, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.constants
        cEco ⇐ land.pools
    end

    ## Instantiate c_QP_vec with the neutral value (one) for every active flow.
    ##
    ## The vector has one element per active carbon transfer, in exactly the same
    ## order as c_flow_order/c_giver/c_taker. This follows the flow-vector design
    ## used by cFlow_GSI and avoids constructing a dense pool-by-pool matrix.
    c_QP_vec = one.(eltype(cEco).(zero([c_taker...])))
    if cEco isa SVector
        c_QP_vec = SVector{length(c_QP_vec)}(c_QP_vec)
    end

    ## The partition vector is consumed by other carbon-cycle processes, so it is
    ## a shared diagnostic rather than a cQualityPartition-private variable.
    @pack_nt c_QP_vec ⇒ land.diagnostics
	return land
end

function precompute(params::cQualityPartition_CASA, forcing, land, helpers)
    @unpack_cQualityPartition_CASA params
    @unpack_nt begin
        c_QP_vec ⇐ land.diagnostics
        (c_flow_order, c_giver, c_taker) ⇐ land.constants
        st_clay ⇐ land.properties
    end

    ## Resolve GSI pool indices from the pool naming convention rather than using
    ## hard-coded integer positions. This keeps the implementation tied to pool
    ## semantics and robust to a reordered cEco pool vector.
    cLitSlow_zix = getZix(cLitSlow, helpers.pools.zix.cLitSlow)
    cSoilSlow_zix = getZix(cSoilSlow, helpers.pools.zix.cSoilSlow)
    cSoilOld_zix = getZix(cSoilOld, helpers.pools.zix.cSoilOld)

    ## CASA-to-GSI mapping
    ## -------------------
    ## Legacy CASA partitions wood litter between a lignin-controlled slow-soil
    ## pathway and a microbial pathway. GSI aggregates that topology: its
    ## cLitSlow pool is explicitly the slow/wood-litter pool and there is no
    ## explicit cMicSurf/cMicSoil pool. The closest flow-level analogue is thus
    ## cLitSlow -> cSoilSlow.
    ##
    ## The old CASA soil-property module also partitions cSoilSlow decomposition
    ## between microbial recycling and old-soil stabilization as a function of
    ## clay. GSI has no explicit cMicSoil pool, but it does retain the
    ## cSoilSlow -> cSoilOld edge. We therefore keep the directly mappable
    ## stabilization fraction on that edge.
    ##
    ## The companion CASA partition parameters for flows *from* cMicSoil cannot
    ## be mapped without inventing a microbial pool/edge and are intentionally
    ## omitted.
    ##
    ## All other active GSI flows retain the neutral value of one. In particular,
    ## vegetation-reserve exchange and shedding are already partitioned by cFlow_GSI
    ## and must not be modified by litter-quality parameters.
    ##
    ## IMPORTANT: because the explicit complementary microbial branches are absent
    ## from the GSI topology, these are effective partition factors. A downstream
    ## carbon-cycle implementation that multiplies transfers by c_QP_vec must
    ## explicitly account for the complementary fraction to preserve carbon balance.
    clay = mean(st_clay)
    qp_neutral = one(frac_lignin_wood)
    qp_lignin = clamp_zero_one(frac_lignin_wood)
    qp_soil_old = clamp_zero_one(frac_clay_cSoilSlow_A + frac_clay_cSoilSlow_B * clay)

    for fO ∈ c_flow_order
        give_r = c_giver[fO]
        take_r = c_taker[fO]

        qp_value = qp_neutral
        if give_r ∈ cLitSlow_zix && take_r ∈ cSoilSlow_zix
            qp_value = qp_lignin
        elseif give_r ∈ cSoilSlow_zix && take_r ∈ cSoilOld_zix
            qp_value = qp_soil_old
        end

        ## c_QP_vec is flow-sized rather than cEco-sized, so use repElem directly
        ## (the same pattern used for c_flow_A_vec in cFlow_GSI).
        c_QP_vec = repElem(c_QP_vec, qp_value, c_QP_vec, c_QP_vec, fO)
    end

    @pack_nt c_QP_vec ⇒ land.diagnostics
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
output `c_QP_vec` is indexed by active flow (`c_flow_order`) rather than by a
dense source-target matrix.

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
