export cMicrobialEfficiencycMic_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiencycMic_CASA{T1,T2,T3} <: cMicrobialEfficiencycMic
    effA::T1 = 0.85 | (0.0, 1.0) | "Intercept of the linear of microbial carbon-transfer efficiency to soil texture." | "" | ""
    effB::T2 = 0.68 | (0.0, Inf) | "Sensitivity of microbial carbon-transfer efficiency to soil texture (silt+clay fraction)." | "" | ""
    eff_cMicSurf_to_cSoilSlow::T3 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of surface microbial turnover into the slow soil pool." | "fraction" | ""
end
#! format: on

function define(params::cMicrobialEfficiencycMic_CASA, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process does
    # not own leaves the efficiency to the other factors.
    c_flow_ME_f_cMic = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_ME_f_cMic ⇒ land.diagnostics
    return land
end

function precompute(params::cMicrobialEfficiencycMic_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cMicrobialEfficiencycMic_CASA params

    ## unpack land variables
    @unpack_nt begin
        c_flow_ME_f_cMic ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
        (st_clay, st_silt) ⇐ land.properties
    end

    ## calculate variables
    # Only the soil microbial pool sees the texture. The surface pool decomposes above
    # the mineral soil, so its turnover carries a fixed efficiency instead. This is the
    # one group whose CASA table mixes a driver with a constant.
    microbial_efficiency = meTextureEfficiency(effA, effB, st_clay, st_silt)

    ME_flows = meCASAFlowsMicrobial(eff_cMicSurf_to_cSoilSlow, microbial_efficiency)

    for (edge, value) ∈ ME_flows
        c_flow_ME_f_cMic = setMEFlow(c_flow_ME_f_cMic, c_flow_named_edges, edge, value)
    end

    ## pack land variables
    @pack_nt c_flow_ME_f_cMic ⇒ land.diagnostics
    return land
end

purpose(::Type{cMicrobialEfficiencycMic_CASA}) = "CASA microbial carbon-transfer efficiency of microbial turnover: texture-dependent for the soil microbial pool, a fixed value for the surface one."

@doc """

	$(getModelDocString(cMicrobialEfficiencycMic_CASA))

---

# Extended help

The approach computes

`c_ME = clamp_zero_one(effA - effB * (mean(st_silt) + mean(st_clay)))`

and writes it into `cMicSoil_to_cSoilSlow` and `cMicSoil_to_cSoilOld`, the two transfers
the CASA texture relation acts on, while `cMicSurf_to_cSoilSlow` takes
`eff_cMicSurf_to_cSoilSlow`. This is the only pathway in the whole CASA efficiency table
with a driver rather than a constant.

Only `CarbonPoolsCASA` has explicit microbial pools. Under the GSI structures all three
edges are absent, `setMEFlow` skips them, and this factor is neutral. Selecting
[`cMicrobialEfficiencycLit_texture`](@ref) and
[`cMicrobialEfficiencycSoil_texture`](@ref) is what carries a texture response there.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cMicrobialEfficiencycMic_CASA
