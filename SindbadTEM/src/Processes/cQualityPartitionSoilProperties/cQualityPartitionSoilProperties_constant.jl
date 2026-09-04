export cQualityPartitionSoilProperties_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartitionSoilProperties_constant{T1,T2} <: cQualityPartitionSoilProperties
    frac_cSoilSlow_to_cSoilOld::T1 = 0.003 | (0.0, 1.0) | "fraction of slow-soil decomposition partitioned to old soil carbon" | "fraction" | ""
    frac_cMicSoil_to_cSoilOld::T2 = 0.003 | (0.0, 1.0) | "fraction of soil-microbial decomposition partitioned to old soil carbon" | "fraction" | ""
end
#! format: on

function define(params::cQualityPartitionSoilProperties_constant, forcing, land, helpers)
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

function precompute(params::cQualityPartitionSoilProperties_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_cQualityPartitionSoilProperties_constant params

    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_soil_props ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
        o_one ⇐ land.constants
    end

    ## calculate variables
    frac_stabilized = (frac_cSoilSlow_to_cSoilOld, frac_cMicSoil_to_cSoilOld)

    for (group, frac) ∈ zip(QP_SOIL_PROPERTIES_GROUPS, frac_stabilized)
        c_flow_QP_f_soil_props = setQPGroup(c_flow_QP_f_soil_props, c_flow_named_edges,
            group, (frac, o_one - frac))
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_soil_props ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitionSoilProperties_constant}) = "Sets the stabilization of slow-soil and soil-microbial decomposition into old soil carbon to uniform constants."

@doc """

	$(getModelDocString(cQualityPartitionSoilProperties_constant))

---

# Extended help

Use this approach to prescribe the two stabilization fractions directly instead
of deriving them from clay content. The defaults are the intercepts of
[`cQualityPartitionSoilProperties_clay`](@ref), which is what that approach returns on a
soil with no clay.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cQualityPartitionSoilProperties_constant
