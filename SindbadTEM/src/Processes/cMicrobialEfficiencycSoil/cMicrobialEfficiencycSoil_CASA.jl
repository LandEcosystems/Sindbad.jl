export cMicrobialEfficiencycSoil_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiencycSoil_CASA{T1,T2} <: cMicrobialEfficiencycSoil
    eff_cSoil_to_cMicSoil::T1 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of slow and old soil decomposition returning to the soil microbial pool." | "fraction" | ""
    eff_cSoilSlow_to_cSoilOld::T2 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of slow soil decomposition stabilized into old soil carbon." | "fraction" | ""
end
#! format: on

function define(params::cMicrobialEfficiencycSoil_CASA, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process does
    # not own leaves the efficiency to the other factors.
    c_flow_ME_f_cSoil = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_ME_f_cSoil ⇒ land.diagnostics
    return land
end

function precompute(params::cMicrobialEfficiencycSoil_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cMicrobialEfficiencycSoil_CASA params

    ## unpack land variables
    @unpack_nt begin
        c_flow_ME_f_cSoil ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
    end

    ## calculate variables
    # The table lives in `meCASAFlowsSoil` so that this factor and the self-contained
    # cMicrobialEfficiency_CASA cannot disagree about it.
    ME_flows = meCASAFlowsSoil(eff_cSoil_to_cMicSoil, eff_cSoilSlow_to_cSoilOld)

    for (edge, value) ∈ ME_flows
        c_flow_ME_f_cSoil = setMEFlow(c_flow_ME_f_cSoil, c_flow_named_edges, edge, value)
    end

    ## pack land variables
    @pack_nt c_flow_ME_f_cSoil ⇒ land.diagnostics
    return land
end

purpose(::Type{cMicrobialEfficiencycSoil_CASA}) = "CASA microbial carbon-transfer efficiencies of slow and old soil decomposition."

@doc """

	$(getModelDocString(cMicrobialEfficiencycSoil_CASA))

---

# Extended help

The two parameters are the soil part of the CASA efficiency matrix that
`cMicrobialEfficiency` used to carry as a dense 14x14 array read by absolute position.

On the GSI structures only `cSoilSlow_to_cSoilOld` exists, so `eff_cSoil_to_cMicSoil`
writes nothing and the approach reduces to one parameter. Note that it applies the CASA
constant there rather than a texture response; select
[`cMicrobialEfficiencycSoil_texture`](@ref) if the soil transfers should respond to
texture on a structure without microbial pools.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cMicrobialEfficiencycSoil_CASA
