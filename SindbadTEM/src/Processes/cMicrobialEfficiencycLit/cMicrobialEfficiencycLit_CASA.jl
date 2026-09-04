export cMicrobialEfficiencycLit_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiencycLit_CASA{T1,T2,T3,T4,T5} <: cMicrobialEfficiencycLit
    eff_cLit_to_cMicSurf::T1 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of litter decomposition into the surface microbial pool." | "fraction" | ""
    eff_cLitRootFine_to_cMicSoil::T2 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of fine-root litter decomposition into the soil microbial pool." | "fraction" | ""
    eff_cLitRootCoarse_to_cMicSoil::T3 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of coarse-root litter decomposition into the soil microbial pool." | "fraction" | ""
    eff_cLit_to_cSoilSlow::T4 = 0.6 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of structural and woody litter decomposition into the slow soil pool." | "fraction" | ""
    eff_cLitRootFine_to_cSoilSlow::T5 = 0.55 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of fine-root structural litter decomposition into the slow soil pool." | "fraction" | ""
end
#! format: on

function define(params::cMicrobialEfficiencycLit_CASA, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process does
    # not own leaves the efficiency to the other factors.
    c_flow_ME_f_cLit = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_ME_f_cLit ⇒ land.diagnostics
    return land
end

function precompute(params::cMicrobialEfficiencycLit_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cMicrobialEfficiencycLit_CASA params

    ## unpack land variables
    @unpack_nt begin
        c_flow_ME_f_cLit ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
    end

    ## calculate variables
    # The table lives in `meCASAFlowsLitter` so that this factor and the self-contained
    # cMicrobialEfficiency_CASA cannot disagree about which litter pool feeds which
    # microbial one.
    ME_flows = meCASAFlowsLitter(eff_cLit_to_cMicSurf, eff_cLitRootFine_to_cMicSoil,
        eff_cLitRootCoarse_to_cMicSoil, eff_cLit_to_cSoilSlow,
        eff_cLitRootFine_to_cSoilSlow)

    for (edge, value) ∈ ME_flows
        c_flow_ME_f_cLit = setMEFlow(c_flow_ME_f_cLit, c_flow_named_edges, edge, value)
    end

    ## pack land variables
    @pack_nt c_flow_ME_f_cLit ⇒ land.diagnostics
    return land
end

purpose(::Type{cMicrobialEfficiencycLit_CASA}) = "CASA microbial carbon-transfer efficiencies of litter decomposition, distinguishing the surface microbial, soil microbial, and direct slow-soil pathways."

@doc """

	$(getModelDocString(cMicrobialEfficiencycLit_CASA))

---

# Extended help

The five parameters are the litter part of the CASA efficiency matrix that
`cMicrobialEfficiency` used to carry as a dense 14x14 array read by absolute position.
Resolving them by name instead is what makes the table checkable, and the check found a
fault the array had hidden: its `cLitRootCoarse` and `cLitWood` columns were transposed,
so coarse-root litter was routed through the surface microbial pool and wood through the
soil one, and the four transfers those columns should have carried got an efficiency of
zero. Their carbon left the giver and arrived nowhere, becoming efflux instead. The
assignment here is the corrected one.

Flows are matched against the configured structure by pool-name pair through
`c_flow_named_edges`, so the CASA-only entries are skipped on the GSI structures and the
`cLitFast`/`cLitSlow` entries are skipped on CASA. One table serves both.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cMicrobialEfficiencycLit_CASA
