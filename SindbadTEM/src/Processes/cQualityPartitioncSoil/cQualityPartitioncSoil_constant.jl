export cQualityPartitioncSoil_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartitioncSoil_constant{T1} <: cQualityPartitioncSoil
    frac_cSoilSlow_to_cSoilOld::T1 = 0.003 | (0.0, 1.0) | "fraction of slow-soil decomposition partitioned to old soil carbon" | "fraction" | ""
end
#! format: on

function define(params::cQualityPartitioncSoil_constant, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_cSoil = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_cSoil ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitioncSoil_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_cQualityPartitioncSoil_constant params

    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_cSoil ⇐ land.diagnostics
        c_flow_qp_groups ⇐ land.cCycleBase
        o_one ⇐ land.constants
    end

    ## calculate variables
    if !isempty(c_flow_qp_groups.cSoil)
        (stabilized_positions, other_positions) = only(c_flow_qp_groups.cSoil)
        for i ∈ stabilized_positions
            c_flow_QP_f_cSoil = repElem(c_flow_QP_f_cSoil, frac_cSoilSlow_to_cSoilOld, i)
        end
        for i ∈ other_positions
            c_flow_QP_f_cSoil = repElem(c_flow_QP_f_cSoil, o_one - frac_cSoilSlow_to_cSoilOld, i)
        end
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_cSoil ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitioncSoil_constant}) = "Sets the stabilization of slow-soil decomposition into old soil carbon to a uniform constant."

@doc """

	$(getModelDocString(cQualityPartitioncSoil_constant))

---

# Extended help

Use this approach to prescribe the stabilization fraction directly instead of
deriving it from clay content. The default is the intercept of
[`cQualityPartitioncSoil_texture`](@ref), which is what that approach returns on a
soil with no clay.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: as the cSoilSlow half of cQualityPartitionSoilProperties_constant
 - 2.0 on 10.09.2026 [skoirala]: split off into its own cQualityPartitioncSoil factor

*Created by*
 - skoirala

"""
cQualityPartitioncSoil_constant
