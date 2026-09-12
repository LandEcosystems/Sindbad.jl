export cQualityPartitioncMic_texture

#! format: off
@bounds @describe @units @timescale @with_kw struct cQualityPartitioncMic_texture{T1,T2} <: cQualityPartitioncMic
    frac_clay_cMicSoil_A::T1 = 0.003 | (0.0, 1.0) | "Intercept of the clay-dependent fraction of soil-microbial decomposition partitioned to old soil carbon." | "fraction" | ""
    frac_clay_cMicSoil_B::T2 = 0.032 | (0.0, Inf) | "Sensitivity of the soil-microbial to old-soil partition fraction to clay content." | "fraction" | ""
end
#! format: on

function define(params::cQualityPartitioncMic_texture, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_cMic = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_cMic ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitioncMic_texture, forcing, land, helpers)
    ## unpack parameters
    @unpack_cQualityPartitioncMic_texture params

    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_cMic ⇐ land.diagnostics
        c_flow_qp_groups ⇐ land.cCycleBase
        st_clay ⇐ land.properties
        o_one ⇐ land.constants
    end

    ## calculate variables
    # Collapse the soil profile to a single mean clay fraction, as `meTextureEfficiency`
    # does for the microbial carbon-transfer efficiency.
    frac_cMicSoil_to_cSoilOld = frac_clay_cMicSoil_A + frac_clay_cMicSoil_B * mean(st_clay)
    if !isempty(c_flow_qp_groups.cMic)
        (stabilized_positions, other_positions) = only(c_flow_qp_groups.cMic)
        for i ∈ stabilized_positions
            c_flow_QP_f_cMic = repElem(c_flow_QP_f_cMic, frac_cMicSoil_to_cSoilOld, i)
        end
        for i ∈ other_positions
            c_flow_QP_f_cMic = repElem(c_flow_QP_f_cMic, o_one - frac_cMicSoil_to_cSoilOld, i)
        end
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_cMic ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitioncMic_texture}) = "Clay-dependent stabilization of soil-microbial decomposition into old soil carbon, as modeled in CASA."

@doc """

	$(getModelDocString(cQualityPartitioncMic_texture))

---

# Extended help

The approach computes

`frac_cMicSoil_to_cSoilOld = frac_clay_cMicSoil_A + frac_clay_cMicSoil_B * mean(st_clay)`

and writes it, with its complement, into the flows of
`land.cCycleBase.c_flow_qp_groups.cMic`. The
parameters and the arithmetic are those of the soil-microbial part of the
now-removed `cQualityPartition_CASA`, which this factor (composed with
[`cQualityPartitioncVeg_vegQualityTraits`](@ref),
[`cQualityPartitioncLit_vegQualityTraits`](@ref) and
[`cQualityPartitioncSoil_texture`](@ref) through [`cQualityPartition_mult`](@ref))
now reproduces exactly.

*References*
 - Carvalhais, N., Reichstein, M., Seixas, J., Collatz, G. J., Pereira, J. S., Berbigier, P., & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for biogeochemical modeling performance and inverse parameter retrieval. Global Biogeochemical Cycles, 22(2).
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: as the cMicSoil half of cQualityPartitionSoilProperties_clay
 - 2.0 on 10.09.2026 [skoirala]: split off into its own single-giver-group cQualityPartitioncMic factor, named _texture for consistency with cMicrobialEfficiencycMic_texture

*Created by*
 - skoirala

"""
cQualityPartitioncMic_texture
