export cQualityPartitionSoilProperties_clay

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartitionSoilProperties_clay{T1,T2,T3,T4} <: cQualityPartitionSoilProperties
    frac_clay_cSoilSlow_A::T1 = 0.003 | (0.0, 1.0) | "Intercept of the clay-dependent fraction of slow-soil decomposition partitioned to old soil carbon." | "fraction" | ""
    frac_clay_cSoilSlow_B::T2 = 0.009 | (0.0, Inf) | "Sensitivity of the slow-soil to old-soil partition fraction to clay content." | "fraction" | ""
    frac_clay_cMicSoil_A::T3 = 0.003 | (0.0, 1.0) | "Intercept of the clay-dependent fraction of soil-microbial decomposition partitioned to old soil carbon." | "fraction" | ""
    frac_clay_cMicSoil_B::T4 = 0.032 | (0.0, Inf) | "Sensitivity of the soil-microbial to old-soil partition fraction to clay content." | "fraction" | ""
end
#! format: on

function define(params::cQualityPartitionSoilProperties_clay, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_soil_props = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_soil_props ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitionSoilProperties_clay, forcing, land, helpers)
    ## unpack parameters
    @unpack_cQualityPartitionSoilProperties_clay params

    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_soil_props ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
        st_clay ⇐ land.properties
        o_one ⇐ land.constants
    end

    ## calculate variables
    # Collapse the soil profile to a single mean clay fraction, as `meTextureEfficiency`
    # does for the microbial carbon-transfer efficiency.
    clay = mean(st_clay)
    frac_cSoilSlow_to_cSoilOld = frac_clay_cSoilSlow_A + frac_clay_cSoilSlow_B * clay
    frac_cMicSoil_to_cSoilOld = frac_clay_cMicSoil_A + frac_clay_cMicSoil_B * clay
    frac_stabilized = (frac_cSoilSlow_to_cSoilOld, frac_cMicSoil_to_cSoilOld)

    for (group, frac) ∈ zip(QP_SOIL_PROPERTIES_GROUPS, frac_stabilized)
        c_flow_QP_f_soil_props = setQPGroup(c_flow_QP_f_soil_props, c_flow_named_edges,
            group, (frac, o_one - frac))
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_soil_props ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitionSoilProperties_clay}) = "Clay-dependent stabilization of slow-soil and soil-microbial decomposition into old soil carbon, as modeled in CASA."

@doc """

	$(getModelDocString(cQualityPartitionSoilProperties_clay))

---

# Extended help

The approach computes

`frac_cSoilSlow_to_cSoilOld = frac_clay_cSoilSlow_A + frac_clay_cSoilSlow_B * mean(st_clay)`

`frac_cMicSoil_to_cSoilOld = frac_clay_cMicSoil_A + frac_clay_cMicSoil_B * mean(st_clay)`

and writes each, with its complement, into the flows of `QP_SOIL_PROPERTIES_GROUPS`. The
parameters and the arithmetic are those of the soil part of
[`cQualityPartition_CASA`](@ref).

*References*
 - Carvalhais, N., Reichstein, M., Seixas, J., Collatz, G. J., Pereira, J. S., Berbigier, P., & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for biogeochemical modeling performance and inverse parameter retrieval. Global Biogeochemical Cycles, 22(2).
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cQualityPartitionSoilProperties_clay
