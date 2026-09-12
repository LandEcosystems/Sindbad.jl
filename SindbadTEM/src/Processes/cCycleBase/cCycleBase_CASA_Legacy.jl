export cCycleBase_CASA_Legacy

"""
    CASA_ANNK_Legacy

Turnover rate of each CASA ecosystem carbon pool, per pool name, exactly as
originally transcribed for `cCycleBase_CASA` (values `[1, 0.03, 0.03, 1, 14.8,
3.9, 18.5, 4.8, 0.2424, 0.2424, 6, 7.3, 0.2, 0.0045]`, in the pool order
`poolStructure(CarbonPoolsCASA)` declares). Fixed data, not a parameter --
calibration happens through `annk_scalar` in `cCycleBase_CASA_Legacy` instead, since
array-valued struct fields cannot be optimized.

Frozen baseline copy of the original `CASA_ANNK`, private to this file: the live
`cCycleBase_CASA` now reads the equivalent, turnover-*time*-valued `CASA_TAU` from
`poolConfigurations/CASA.jl` instead. Kept here, rate-valued and unchanged, so
`cCycleBase_CASA_Legacy` can be run side by side against `cCycleBase_CASA` and diffed.
"""
const CASA_ANNK_Legacy = (;
    cVegRootFine = 1.0,
    cVegRootCoarse = 0.03,
    cVegWood = 0.03,
    cVegLeaf = 1.0,
    cLitLeafFast = 14.8,
    cLitLeafSlow = 3.9,
    cLitRootFineFast = 18.5,
    cLitRootFineSlow = 4.8,
    cLitRootCoarse = 0.2424,
    cLitWood = 0.2424,
    cMicSurf = 6.0,
    cMicSoil = 7.3,
    cSoilSlow = 0.2,
    cSoilOld = 0.0045,
)

#! format: off
@bounds @describe @units @timescale @with_kw struct cCycleBase_CASA_Legacy{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15} <: cCycleBase
    annk_scalar::T1 = 1.0 | (0.25, 4.0) | "scalar for the per-pool turnover rate of ecosystem carbon pools" | "-" | ""
    cVegRootFine_age_scalar::T2 = 1.0 | (0.25, 4.0) | "scalar for the per-PFT mean age of fine roots" | "-" | ""
    cVegRootCoarse_age_scalar::T3 = 1.0 | (0.25, 4.0) | "scalar for the per-PFT mean age of coarse roots" | "-" | ""
    cVegWood_age_scalar::T4 = 1.0 | (0.25, 4.0) | "scalar for the per-PFT mean age of wood" | "-" | ""
    cVegLeaf_age_scalar::T5 = 1.0 | (0.25, 4.0) | "scalar for the per-PFT mean age of leaves" | "-" | ""
    p_C_to_N_cVeg::T6 = Float64.([25.0, 260.0, 260.0, 25.0]) | (-Inf, Inf) | "carbon to nitrogen ratio in vegetation pools" | "gC/gN" | ""
    eff_cLit_to_cMicSurf::T7 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of litter decomposition into the surface microbial pool." | "fraction" | ""
    eff_cLitRootFine_to_cMicSoil::T8 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of fine-root litter decomposition into the soil microbial pool." | "fraction" | ""
    eff_cLitRootCoarse_to_cMicSoil::T9 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of coarse-root litter decomposition into the soil microbial pool." | "fraction" | ""
    eff_cLit_to_cSoilSlow::T10 = 0.6 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of structural and woody litter decomposition into the slow soil pool." | "fraction" | ""
    eff_cLitRootFine_to_cSoilSlow::T11 = 0.55 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of fine-root structural litter decomposition into the slow soil pool." | "fraction" | ""
    eff_cMicSurf_to_cSoilSlow::T12 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of surface microbial turnover into the slow soil pool." | "fraction" | ""
    eff_cSoil_to_cMicSoil::T13 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of slow and old soil decomposition returning to the soil microbial pool." | "fraction" | ""
    eff_cSoilSlow_to_cSoilOld::T14 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of slow soil decomposition stabilized into old soil carbon." | "fraction" | ""
    c_remain::T15 = 50.0 | (0.1, 100.0) | "remaining carbon after disturbance" | "gC/m2" | ""
end
#! format: on

function define(params::cCycleBase_CASA_Legacy, forcing, land, helpers)
    @unpack_cCycleBase_CASA_Legacy params

    @unpack_nt begin
        cEco ⇐ land.pools
    end

    # one flow per declared edge of this approach, resolved against the configured
    # pool structure, rather than a transfer matrix carried as a parameter. The same
    # call keys the flows by pool-name pair and sizes the neutral flow vector, so a
    # cFlow approach reads the topology and fills in values instead of rederiving both
    (c_flow_order, c_taker, c_giver, pool_names, flow_edges, c_flow_qp_groups, c_flow_A_vec,
        c_flow_QP_vec, c_flow_ME_vec) = cFlowStructure(params, cEco, helpers)

    ## Instantiate variables, matching cCycleBase_GSI_PlantForm.jl: define only
    ## sets up structure (topology, zero-initialized arrays) and runs once ever,
    ## never on later parameter realizations, so nothing here may depend on an
    ## actual parameter value -- that happens in precompute instead.
    C_to_N_cVeg = zero(cEco)
    c_eco_k_base = zero(cEco)

    c_model = cCycleBase_CASA_Legacy()

    ## pack land variables
    @pack_nt begin
        (C_to_N_cVeg, c_eco_k_base, c_flow_A_vec, c_flow_QP_vec, c_flow_ME_vec) ⇒ land.diagnostics
        (c_flow_order, c_taker, c_giver, pool_names, flow_edges, c_flow_qp_groups) ⇒ land.cCycleBase
        c_model ⇒ land.models
    end
    return land
end

function precompute(params::cCycleBase_CASA_Legacy, forcing, land, helpers)
    ## unpack parameters
    @unpack_cCycleBase_CASA_Legacy params

    ## unpack land variables
    @unpack_nt begin
        C_to_N_cVeg ⇐ land.diagnostics
        c_eco_k_base ⇐ land.diagnostics
        c_flow_ME_vec ⇐ land.diagnostics
        (c_giver, c_taker) ⇐ land.cCycleBase
    end
    zix = helpers.pools.zix

    ## calculate variables
    # CASA's own static microbial-efficiency table, applied on top of the
    # neutral c_flow_ME_vec define allocated. Lives here, not in define, since
    # the eff_* fields are ordinary optimizable parameters: precompute runs
    # once per parameter realization, so a value the optimizer changes is
    # picked up on the next iteration, unlike define which runs once ever. The
    # two soil-microbial edges this does not cover keep the neutral default
    # unless a texture-driven approach is selected (cMicrobialEfficiencycMic_texture,
    # or the per-group _CASA trio for the exact CASA distinction between the
    # surface and soil microbial pathways).
    ME_flows = (
        meCASAFlowsLitter(eff_cLit_to_cMicSurf, eff_cLitRootFine_to_cMicSoil,
            eff_cLitRootCoarse_to_cMicSoil, eff_cLit_to_cSoilSlow,
            eff_cLitRootFine_to_cSoilSlow, zix)...,
        (zix.cMicSurf, zix.cSoilSlow, eff_cMicSurf_to_cSoilSlow),
        meCASAFlowsSoil(eff_cSoil_to_cMicSoil, eff_cSoilSlow_to_cSoilOld, zix)...,
    )
    for (giver_zix, taker_zix, value) ∈ ME_flows
        c_flow_ME_vec = setMEFlow(c_flow_ME_vec, c_giver, c_taker, giver_zix, taker_zix, value)
    end

    # carbon to nitrogen ratio [gC.gN-1]. Bulk tuple-indexed broadcasting
    # assignment (C_to_N_cVeg[helpers.pools.zix.cVeg] .= p_C_to_N_cVeg) is not
    # supported on the land array types used here (land.diagnostics arrays are
    # immutable SVectors); every GSI-family cCycleBase carries that exact line
    # commented out for the same reason, replaced by this type-stable
    # per-element loop.
    vegZix = helpers.pools.zix.cVeg
    for ix ∈ eachindex(vegZix)
        @rep_elem p_C_to_N_cVeg[ix] ⇒ (C_to_N_cVeg, vegZix[ix])
    end

    # turnover rates, by pool name rather than by cEco position, so a
    # structure that ordered pools differently still gets its turnovers in
    # the right slots -- same convention cCycleBase_GSI_PlantForm.jl uses.
    for ix ∈ helpers.pools.zix.cVegRootFine
        @rep_elem CASA_ANNK_Legacy.cVegRootFine * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cVegRootCoarse
        @rep_elem CASA_ANNK_Legacy.cVegRootCoarse * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cVegWood
        @rep_elem CASA_ANNK_Legacy.cVegWood * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cVegLeaf
        @rep_elem CASA_ANNK_Legacy.cVegLeaf * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cLitLeafFast
        @rep_elem CASA_ANNK_Legacy.cLitLeafFast * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cLitLeafSlow
        @rep_elem CASA_ANNK_Legacy.cLitLeafSlow * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cLitRootFineFast
        @rep_elem CASA_ANNK_Legacy.cLitRootFineFast * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cLitRootFineSlow
        @rep_elem CASA_ANNK_Legacy.cLitRootFineSlow * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cLitRootCoarse
        @rep_elem CASA_ANNK_Legacy.cLitRootCoarse * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cLitWood
        @rep_elem CASA_ANNK_Legacy.cLitWood * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cMicSurf
        @rep_elem CASA_ANNK_Legacy.cMicSurf * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cMicSoil
        @rep_elem CASA_ANNK_Legacy.cMicSoil * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cSoilSlow
        @rep_elem CASA_ANNK_Legacy.cSoilSlow * annk_scalar ⇒ (c_eco_k_base, ix)
    end
    for ix ∈ helpers.pools.zix.cSoilOld
        @rep_elem CASA_ANNK_Legacy.cSoilOld * annk_scalar ⇒ (c_eco_k_base, ix)
    end

    ## pack land variables
    @pack_nt begin
        (C_to_N_cVeg, c_eco_k_base, c_flow_ME_vec) ⇒ land.diagnostics
        c_remain ⇒ land.states
    end
    return land
end

poolConfiguration(::Type{<:cCycleBase_CASA_Legacy}) = CarbonPoolsCASA
cFlowEdges(::Type{<:cCycleBase_CASA_Legacy}) = CASA_FLOW_EDGES
purpose(::Type{cCycleBase_CASA_Legacy}) = "Structure and properties of the carbon cycle components used in the CASA approach. Frozen pre-centralization baseline, kept for side-by-side comparison against cCycleBase_CASA."

@doc """

$(getModelDocString(cCycleBase_CASA_Legacy))

---

# Extended help

Frozen baseline: byte-for-byte the same parameters and logic `cCycleBase_CASA` had
before its turnover/C:N defaults were centralized into `poolConfigurations/CASA.jl`,
kept here unchanged (including its own private `CASA_ANNK_Legacy` copy) so the
redesign can be run side by side against it and diffed.

# Pool topology

The 22 giver-to-taker links of this approach are declared as `CASA_FLOW_EDGES` in
`poolConfigurations/CASA.jl`, and the pools they name as
`poolStructure(CarbonPoolsCASA)` beside it.

# Microbial efficiency

`precompute` also carries CASA's static microbial-carbon-transfer-efficiency table
as ordinary bounded parameters (`eff_cLit_to_cMicSurf` and the other seven), and
writes them into `c_flow_ME_vec` itself.

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].
 - Potter, C., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003).  Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data & ecosystem  modeling 1982–1998. Global & Planetary Change, 39[3-4], 201-213.
 - Potter; C. S.; Randerson; J. T.; Field; C. B.; Matson; P. A.; Vitousek; P. M.; Mooney; H. A.  & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global  satellite & surface data. Global Biogeochemical Cycles, 7[4], 811-841.

*Versions*
 - 1.0 on 28.05.2022 [skoirala | @dr-ko]: migrate to julia
 - 1.6 on 10.09.2026 [skoirala]: (history inherited from cCycleBase_CASA up to this point)
 - 1.7 on 11.09.2026 [skoirala]: split off from cCycleBase_CASA as the frozen
   pre-centralization baseline, with its own private `CASA_ANNK_Legacy` copy,
   for side-by-side comparison

*Created by*
 - ncarvalhais
"""
cCycleBase_CASA_Legacy
