export cQualityPartitionLignin_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartitionLignin_constant{T1,T2} <: cQualityPartitionLignin
    frac_lignin_struct::T1 = 0.3 | (0.0, 1.0) | "lignin as a fraction of structural litter carbon" | "fraction" | ""
    frac_lignin_wood::T2 = 0.4 | (0.0, 1.0) | "lignin fraction of woody litter" | "fraction" | ""
end
#! format: on

function define(params::cQualityPartitionLignin_constant, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_lignin = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_lignin ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitionLignin_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_cQualityPartitionLignin_constant params

    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_lignin ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
        o_one ⇐ land.constants
    end

    ## calculate variables
    for (stabilized_edge, microbial_edge) ∈ QP_LIGNIN_STRUCT_GROUPS
        c_flow_QP_f_lignin = setQPGroup(c_flow_QP_f_lignin, c_flow_named_edges,
            (stabilized_edge, microbial_edge),
            (frac_lignin_struct, o_one - frac_lignin_struct))
    end
    for (stabilized_edge, microbial_edge) ∈ QP_LIGNIN_WOOD_GROUPS
        c_flow_QP_f_lignin = setQPGroup(c_flow_QP_f_lignin, c_flow_named_edges,
            (stabilized_edge, microbial_edge),
            (frac_lignin_wood, o_one - frac_lignin_wood))
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_lignin ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitionLignin_constant}) = "Sets the lignin control of the carbon-quality partition to uniform constants for structural and woody litter."

@doc """

	$(getModelDocString(cQualityPartitionLignin_constant))

---

# Extended help

Use this approach to prescribe the two lignin fractions directly instead of
varying them with PFT class. The defaults are those of
[`lignin_constant`](@ref).

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cQualityPartitionLignin_constant
