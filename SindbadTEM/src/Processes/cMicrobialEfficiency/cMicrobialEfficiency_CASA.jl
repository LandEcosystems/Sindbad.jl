export cMicrobialEfficiency_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiency_CASA{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10} <: cMicrobialEfficiency
    effA::T1 = 0.85 | (0.0, 1.0) | "Intercept of the linear of microbial carbon-transfer efficiency to soil texture." | "" | ""
    effB::T2 = 0.68 | (0.0, Inf) | "Sensitivity of microbial carbon-transfer efficiency to soil texture (silt+clay fraction)." | "" | ""
    eff_cLit_to_cMicSurf::T3 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of litter decomposition into the surface microbial pool." | "fraction" | ""
    eff_cLitRootFine_to_cMicSoil::T4 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of fine-root litter decomposition into the soil microbial pool." | "fraction" | ""
    eff_cLitRootCoarse_to_cMicSoil::T5 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of coarse-root litter decomposition into the soil microbial pool." | "fraction" | ""
    eff_cLit_to_cSoilSlow::T6 = 0.6 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of structural and woody litter decomposition into the slow soil pool." | "fraction" | ""
    eff_cLitRootFine_to_cSoilSlow::T7 = 0.55 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of fine-root structural litter decomposition into the slow soil pool." | "fraction" | ""
    eff_cMicSurf_to_cSoilSlow::T8 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of surface microbial turnover into the slow soil pool." | "fraction" | ""
    eff_cSoil_to_cMicSoil::T9 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of slow and old soil decomposition returning to the soil microbial pool." | "fraction" | ""
    eff_cSoilSlow_to_cSoilOld::T10 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of slow soil decomposition stabilized into old soil carbon." | "fraction" | ""
end
#! format: on

function precompute(params::cMicrobialEfficiency_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cMicrobialEfficiency_CASA params

    ## unpack land variables
    @unpack_nt begin
        c_flow_ME_vec ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
        (st_clay, st_silt) ⇐ land.properties
    end

    ## calculate variables
    # The whole CASA table, assembled from the same three per-group declarations the
    # factor approaches use. Writing it out again here instead would put the assignment
    # of litter pool to microbial pool in two places, which is how the dense array it
    # replaced came to have its coarse-root and wood columns transposed.
    #
    # The three pool-group factors are deliberately not read, so this approach can be
    # selected on its own, with no other process in the model structure.
    microbial_efficiency = meTextureEfficiency(effA, effB, st_clay, st_silt)
    ME_flows = (
        meCASAFlowsLitter(eff_cLit_to_cMicSurf, eff_cLitRootFine_to_cMicSoil,
            eff_cLitRootCoarse_to_cMicSoil, eff_cLit_to_cSoilSlow,
            eff_cLitRootFine_to_cSoilSlow)...,
        meCASAFlowsMicrobial(eff_cMicSurf_to_cSoilSlow, microbial_efficiency)...,
        meCASAFlowsSoil(eff_cSoil_to_cMicSoil, eff_cSoilSlow_to_cSoilOld)...,
    )

    for (edge, value) ∈ ME_flows
        c_flow_ME_vec = setMEFlow(c_flow_ME_vec, c_flow_named_edges, edge, value)
    end

    ## pack land variables
    @pack_nt c_flow_ME_vec ⇒ land.diagnostics
    return land
end

purpose(::Type{cMicrobialEfficiency_CASA}) = "Represent CASA-style microbial carbon-transfer efficiency as one self-contained table over the litter, microbial and soil decomposition pathways, with the soil microbial pool responding to texture."

@doc """

	$(getModelDocString(cMicrobialEfficiency_CASA))

---
# Extended help

This is the self-contained counterpart of composing
[`cMicrobialEfficiencycLit_CASA`](@ref), [`cMicrobialEfficiencycMic_CASA`](@ref) and
[`cMicrobialEfficiencycSoil_CASA`](@ref) through [`cMicrobialEfficiency_mult`](@ref). It
produces the same `c_flow_ME_vec` from the same declarations, in one process selection
rather than four, and reads none of the factor diagnostics, so no other process has to be
present in the model structure.

Use the composed path when one pool group's treatment needs to be swapped or calibrated
apart from the others; use this when a single CASA declaration is what is wanted.

The `_CASA` parameters are duplicated between this approach and the three factors, the
way [`cQualityPartition_CASA`](@ref) duplicates the defaults of the factors it stands in
for. The *tables* are not duplicated: `meCASAFlowsLitter`, `meCASAFlowsMicrobial` and
`meCASAFlowsSoil` are declared once each, beside the process that owns those transfers,
and both paths call them.

It replaces the dense 14x14 `c_flow_ME_array` parameter this process used to carry, read
by absolute position. Resolving the table by name is what made it checkable, and the check
found a fault the array had hidden: its `cLitRootCoarse` and `cLitWood` columns were
transposed, so coarse-root litter was routed through the surface microbial pool and wood
through the soil one, and the four transfers those columns should have carried got an
efficiency of zero. Their carbon left the giver and arrived nowhere, becoming efflux
instead. The assignment here is the corrected one.

Flows are matched against the configured structure by pool-name pair through
`c_flow_named_edges`, so edges the selected structure lacks are simply skipped. Its
texture term therefore only reaches a structure that has a soil microbial pool; on the GSI
structures every transfer here carries a constant, and
[`cMicrobialEfficiencycLit_texture`](@ref) with
[`cMicrobialEfficiencycSoil_texture`](@ref) is what gives those a texture response.

*References*
 - Carvalhais, N., Reichstein, M., Seixas, J., Collatz, G. J., Pereira, J. S., Berbigier, P., & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for biogeochemical modeling performance and inverse parameter retrieval. Global Biogeochemical Cycles, 22(2).
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 27.08.2026 [sol]
 - 2.0 on 04.09.2026 [skoirala]: c_flow_ME_array replaced by named parameters matched through c_flow_named_edges; c_flow_ME_vec allocated by cCycleBase; corrected the transposed coarse-root and wood pathways
 - 2.1 on 04.09.2026 [skoirala]: tables shared with the per-pool-group factor approaches

*Created by*
 - ncarvalhais

"""
cMicrobialEfficiency_CASA
