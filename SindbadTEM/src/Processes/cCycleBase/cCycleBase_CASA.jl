export cCycleBase_CASA
export meCASAFlowsLitter
export meCASAFlowsSoil

"""
    meCASAFlowsLitter(eff_cLit_to_cMicSurf, eff_cLitRootFine_to_cMicSoil,
        eff_cLitRootCoarse_to_cMicSoil, eff_cLit_to_cSoilSlow,
        eff_cLitRootFine_to_cSoilSlow, zix)

The CASA microbial carbon-transfer efficiency of every litter decomposition pathway, as
`(giver_zix, taker_zix, value)` triples matched by pool-index membership
(`setMEFlow`/`edgesBetween` in `landUtils.jl`), not by a literal
`<giver>_to_<taker>` name.

The surface microbial pathway retains least, the direct route into slow soil most, and
fine roots sit between the two because they decompose in the soil rather than at the
surface.

Only ever called from `cCycleBase_CASA`'s own `precompute`, so `zix` is always
CASA's. Declared as a function rather than written inline in `precompute`, and read
from one place, since this is the assignment whose `cLitRootCoarse` and `cLitWood`
columns were transposed for as long as it was a dense array indexed by position.
"""
function meCASAFlowsLitter(eff_cLit_to_cMicSurf, eff_cLitRootFine_to_cMicSoil,
        eff_cLitRootCoarse_to_cMicSoil, eff_cLit_to_cSoilSlow,
        eff_cLitRootFine_to_cSoilSlow, zix)
    return (
        ((zix.cLitLeaf..., zix.cLitWood...), zix.cMicSurf, eff_cLit_to_cMicSurf),
        (zix.cLitRootFine, zix.cMicSoil, eff_cLitRootFine_to_cMicSoil),
        (zix.cLitRootCoarse, zix.cMicSoil, eff_cLitRootCoarse_to_cMicSoil),
        ((zix.cLitLeafSlow..., zix.cLitRootCoarse..., zix.cLitWood...), zix.cSoilSlow, eff_cLit_to_cSoilSlow),
        (zix.cLitRootFineSlow, zix.cSoilSlow, eff_cLitRootFine_to_cSoilSlow),
    )
end

"""
    meCASAFlowsSoil(eff_cSoil_to_cMicSoil, eff_cSoilSlow_to_cSoilOld, zix)

The CASA microbial carbon-transfer efficiency of the soil decomposition pathways, as
`(giver_zix, taker_zix, value)` triples matched by pool-index membership
(`setMEFlow`/`edgesBetween` in `landUtils.jl`), not by a literal
`<giver>_to_<taker>` name.

The two routes carry the same CASA value but are separate parameters so that
stabilization into old soil carbon and the return to the microbial pool can be
calibrated apart.
"""
function meCASAFlowsSoil(eff_cSoil_to_cMicSoil, eff_cSoilSlow_to_cSoilOld, zix)
    return (
        (zix.cSoil, zix.cMicSoil, eff_cSoil_to_cMicSoil),
        (zix.cSoilSlow, zix.cSoilOld, eff_cSoilSlow_to_cSoilOld),
    )
end

#! format: off
@bounds @describe @units @timescale @with_kw struct cCycleBase_CASA{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15,T16,T17,T18,T19,T20,T21,T22,T23,T24,T25} <: cCycleBase
    k_c_rootfine_scalar::T1 = 1.0 | (0.25, 4.0) | "scalar for the per-vegetation-type turnover rate of fine roots" | "year-1" | "year"
    k_c_rootcoarse_scalar::T2 = 1.0 | (0.25, 4.0) | "scalar for the per-vegetation-type turnover rate of coarse roots" | "year-1" | "year"
    k_c_wood_scalar::T3 = 1.0 | (0.25, 4.0) | "scalar for the per-vegetation-type turnover rate of wood" | "year-1" | "year"
    k_c_leaf_scalar::T4 = 1.0 | (0.25, 4.0) | "scalar for the per-vegetation-type turnover rate of leaves" | "year-1" | "year"

    k_c_litfast_scalar::T5 = 1.0 | (0.25, 4) | "scalar for turnover rate of fast litter carbon pools" | "year-1" | "year"
    k_c_litslow_scalar::T6 = 1.0 | (0.25, 4) | "scalar for turnover rate of slow litter carbon pools" | "year-1" | "year"

    k_c_micsurf_scalar::T7 = 1.0 | (0.25, 4.0) | "scalar for the per-pool turnover rate of ecosystem carbon pools" | "year-1" | "year"
    k_c_micsoil_scalar::T8 = 1.0 | (0.25, 4.0) | "scalar for the per-pool turnover rate of ecosystem carbon pools" | "year-1" | "year"

    k_c_soilslow_scalar::T9 = 1.0 | (0.25, 4) | "scalar for turnover rate of soil slow carbon pool" | "year-1" | "year"
    k_c_soilold_scalar::T10 = 1.0 | (0.25, 4) | "scalar for turnover rate of soil old carbon pool" | "year-1" | "year"

    α_k_cVeg::T11 = 1.0 | (0.25, 4.0) | "scalar for turnover rate of all vegetation carbon pools; it has no timescale, since it scales the original pool level k." | "-" | ""
    α_k_cLit::T12 = 1.0 | (0.25, 4) | "scalar for turnover rate of all litter carbon pools; it has no timescale, since it scales the original pool level k." | "-" | ""
    α_k_cSoil::T13 = 1.0 | (0.25, 4) | "scalar for turnover rate of all soil carbon pools; it has no timescale, since it scales the original pool level k." | "-" | ""
    α_k_cMic::T14 = 1.0 | (0.25, 4) | "scalar for turnover rate of all microbial carbon pools; it has no timescale, since it scales the original pool level k." | "-" | ""

    CN_ratio_scalar::T15 = 1.0 | (0.25, 4.0) | "scalar for the vegetation carbon-to-nitrogen ratio" | "-" | ""
    eff_cLit_to_cMicSurf::T16 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of litter decomposition into the surface microbial pool." | "fraction" | ""
    eff_cLitRootFine_to_cMicSoil::T17 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of fine-root litter decomposition into the soil microbial pool." | "fraction" | ""
    eff_cLitRootCoarse_to_cMicSoil::T18 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of coarse-root litter decomposition into the soil microbial pool." | "fraction" | ""
    eff_cLit_to_cSoilSlow::T19 = 0.6 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of structural and woody litter decomposition into the slow soil pool." | "fraction" | ""
    eff_cLitRootFine_to_cSoilSlow::T20 = 0.55 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of fine-root structural litter decomposition into the slow soil pool." | "fraction" | ""
    eff_cMicSurf_to_cSoilSlow::T21 = 0.4 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of surface microbial turnover into the slow soil pool." | "fraction" | ""
    eff_cSoil_to_cMicSoil::T22 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of slow and old soil decomposition returning to the soil microbial pool." | "fraction" | ""
    eff_cSoilSlow_to_cSoilOld::T23 = 0.45 | (0.0, 1.0) | "Microbial carbon-transfer efficiency of slow soil decomposition stabilized into old soil carbon." | "fraction" | ""
    c_remain_scalar::T24 = 1.0 | (0.1, 10.0) | "scalar for the per-vegetation-type minimum remaining carbon after disturbance" | "-" | ""
    k_hilo_scalar::T25 = 1.0 | (-Inf, Inf) | "timescale factor for split of high and low turnover rates" | "-" | "year"
end
#! format: on

function define(params::cCycleBase_CASA, forcing, land, helpers)
    @unpack_cCycleBase_CASA params

    @unpack_nt begin
        cEco ⇐ land.pools
        veg_type_class_map ⇐ land.vegClass
    end

    # one flow per declared edge of this approach, resolved against the configured
    # pool structure, rather than a transfer matrix carried as a parameter. The same
    # call keys the flows by pool-name pair and sizes the neutral flow vector, so a
    # cFlow approach reads the topology and fills in values instead of rederiving both
    (c_flow_order, c_taker, c_giver, pool_names, flow_edges, c_flow_taker_turnover_rank, c_flow_A_vec,
        c_flow_QP_vec, c_flow_ME_vec) = cFlowStructure(params, cEco, helpers)

    ## Instantiate variables, matching cCycleBase_GSI_PlantForm.jl: define only
    ## sets up structure (topology, zero-initialized arrays) and runs once ever,
    ## never on later parameter realizations, so nothing here may depend on an
    ## actual parameter value -- that happens in precompute instead.
    CN_ratio_cVeg = zero(cEco)
    c_eco_k_base = zero(cEco)

    # Re-keyed once, at define time, onto whichever classification the experiment's
    # vegClass approach resolved into (the canonical vocabulary, or a grouping like
    # Classification_PlantForm) -- see getParamsPerVegType, and
    # vegQualityTraits_vegType.jl for the same pattern applied to litter chemistry.
    rootfine_age_per_vegtype = getParamsPerVegType(CVEG_ROOTFINE_AGE_PER_VEGTYPE, typeof(veg_type_class_map))
    leaf_age_per_vegtype = getParamsPerVegType(CVEG_LEAF_AGE_PER_VEGTYPE, typeof(veg_type_class_map))
    rootcoarse_age_per_vegtype = getParamsPerVegType(CVEG_ROOTCOARSE_AGE_PER_VEGTYPE, typeof(veg_type_class_map))
    wood_age_per_vegtype = getParamsPerVegType(CVEG_WOOD_AGE_PER_VEGTYPE, typeof(veg_type_class_map))
    c_remain_per_vegtype = getParamsPerVegType(C_REMAIN_PER_VEGTYPE, typeof(veg_type_class_map))

    # zix for the carbon cycle...
    zix_cNonVeg, zix_cNatural, zix_cHeterotrophic, zix_cProducts = cCycleBaseZixGroups(helpers)
    c_model = params

    ## pack land variables
    @pack_nt begin
        (CN_ratio_cVeg, c_eco_k_base, c_flow_A_vec, c_flow_QP_vec, c_flow_ME_vec) ⇒ land.diagnostics
        (rootfine_age_per_vegtype, leaf_age_per_vegtype, rootcoarse_age_per_vegtype, wood_age_per_vegtype) ⇒ land.diagnostics
        c_remain_per_vegtype ⇒ land.diagnostics
        (c_flow_order, c_taker, c_giver, pool_names, flow_edges, c_flow_taker_turnover_rank) ⇒ land.cCycleBase
        (zix_cNonVeg, zix_cNatural, zix_cHeterotrophic, zix_cProducts) ⇒ land.cCycleBase
        c_model ⇒ land.models
    end
    return land
end

function precompute(params::cCycleBase_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cCycleBase_CASA params

    ## unpack land variables
    @unpack_nt begin
        CN_ratio_cVeg ⇐ land.diagnostics
        c_eco_k_base ⇐ land.diagnostics
        c_flow_ME_vec ⇐ land.diagnostics
        (rootfine_age_per_vegtype, leaf_age_per_vegtype, rootcoarse_age_per_vegtype, wood_age_per_vegtype) ⇐ land.diagnostics
        c_remain_per_vegtype ⇐ land.diagnostics
        (c_flow_order, c_giver, c_taker, c_flow_taker_turnover_rank) ⇐ land.cCycleBase
        veg_type_name ⇐ land.states
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

    # carbon to nitrogen ratio [gC.gN-1] and turnover rate, both by pool name rather
    # than by cEco position, so a structure that ordered pools differently still gets
    # both in the right slots -- same convention cCycleBase_GSI_PlantForm.jl uses.
    # Bulk tuple-indexed broadcasting assignment is not supported on the land array
    # types used here (land.diagnostics arrays are immutable SVectors); every
    # GSI-family cCycleBase carries that exact note for the same reason, replaced by
    # getKfromTau/getCNfromParams, their own functions rather than inline loops
    # here so Julia can infer this function's return type concretely (see
    # getKfromTau's docstring, poolConfigurations/poolConfigurations.jl).
    CN_ratio_cVeg = getCNfromParams(CN_ratio_cVeg, CASA_CN_ratio, CN_ratio_scalar, helpers)

    # The four vegetation-compartment pools' turnover varies by land.states.veg_type_name,
    # looked up in the tables define re-keyed from ParamsForVegClasses.jl, each
    # scaled by its own bounded multiplier (k_c_rootfine_scalar/k_c_leaf_scalar/
    # k_c_rootcoarse_scalar/k_c_wood_scalar) through the same
    # getKfromTau(scalar_for::NamedTuple) convention every other per-pool
    # scalar in this codebase uses: rate = (1/turnover_time) * scalar. Every
    # other CASA pool (litter/microbial/soil) is not vegetation-type dependent
    # and stays on the fixed CASA_TAU_NON_VEG_POOLS table with the single shared k_c_scalar.
    casa_tau_default_veg_pools = (;
        cVegRootFine = getproperty(rootfine_age_per_vegtype, veg_type_name),
        cVegLeaf = getproperty(leaf_age_per_vegtype, veg_type_name),
        cVegRootCoarse = getproperty(rootcoarse_age_per_vegtype, veg_type_name),
        cVegWood = getproperty(wood_age_per_vegtype, veg_type_name),
    )
    casa_k_veg_scalars = (;
        cVegRootFine = k_c_rootfine_scalar * α_k_cVeg, 
        cVegLeaf = k_c_leaf_scalar * α_k_cVeg,
        cVegRootCoarse = k_c_rootcoarse_scalar * α_k_cVeg, 
        cVegWood = k_c_wood_scalar * α_k_cVeg,
    )

    casa_k_non_veg_scalars = (;
        cLitLeafFast = k_c_litfast_scalar * α_k_cLit,
        cLitLeafSlow = k_c_litslow_scalar * α_k_cLit,
        cLitRootFineFast = k_c_litfast_scalar * α_k_cLit,
        cLitRootFineSlow = k_c_litslow_scalar * α_k_cLit,
        cLitRootCoarse = k_c_litslow_scalar * α_k_cLit,
        cLitWood = k_c_litslow_scalar * α_k_cLit,
        cMicSurf = k_c_micsurf_scalar * α_k_cMic,
        cMicSoil = k_c_micsoil_scalar * α_k_cMic,
        cSoilSlow = k_c_soilslow_scalar * α_k_cSoil,
        cSoilOld = k_c_soilold_scalar * α_k_cSoil,
    )

    c_eco_k_base = getKfromTau(c_eco_k_base, casa_tau_default_veg_pools, casa_k_veg_scalars, helpers)
    c_eco_k_base = getKfromTau(c_eco_k_base, CASA_TAU_NON_VEG_POOLS, casa_k_non_veg_scalars, helpers)

    # minimum remaining carbon after disturbance, by land.states.veg_type_name,
    # looked up in the table define re-keyed from C_REMAIN_PER_VEGTYPE, scaled
    # by the bounded c_remain_scalar -- same getParamForVegType idiom
    # vegQualityTraits_vegType.jl uses for litter chemistry.
    c_remain = getParamForVegType(c_remain_per_vegtype, veg_type_name, c_remain_scalar)

    k_hilo_lit_split = k_hilo_scalar / (oftype(k_hilo_scalar, TAU_HILO_LIT_SPLIT)) # TAU_HILO_LIT_SPLIT is changed to actual time scale through 'year' timescale of k_hilo_scalar which will be 1/365 for daily model run ...

    # c_flow_taker_turnover_rank ranks by base turnover rate, so it can only be
    # derived now that c_eco_k_base above holds real values -- define only
    # allocated it, zero-filled, since it runs before any precompute.
    c_flow_taker_turnover_rank = getTakerTurnoverRank(
        c_flow_taker_turnover_rank,
        c_flow_order,
        c_giver,
        c_taker,
        c_eco_k_base,
        helpers.pools.zix.cVeg,
    )

    ## pack land variables
    @pack_nt begin
        (CN_ratio_cVeg, c_eco_k_base, c_flow_ME_vec) ⇒ land.diagnostics
        c_remain ⇒ land.states
        (c_flow_taker_turnover_rank, k_hilo_lit_split) ⇒ land.cCycleBase
    end
    return land
end

poolConfiguration(::Type{<:cCycleBase_CASA}) = CASA
purpose(::Type{cCycleBase_CASA}) = "Structure and properties of the carbon cycle components used in the CASA approach."

@doc """

$(getModelDocString(cCycleBase_CASA))

---

# Extended help

# Pool topology

The 22 giver-to-taker links of this approach are declared as `CASA_FLOW_EDGES` in
`poolConfigurations/CASA.jl`, and the pools they name as `poolStructure(CASA)`
beside it. `cFlowMatrix(cCycleBase_CASA, pool_names)` returns them as a
`[taker, giver]` matrix of flow indices, and `plotCarbonFlows` draws them.

# Microbial efficiency

`precompute` carries CASA's static microbial-carbon-transfer-efficiency table as
ordinary bounded parameters (`eff_cLit_to_cMicSurf` and the other seven) and writes
them into `c_flow_ME_vec`, giving CASA a realistic default with no
`cMicrobialEfficiency` approach selected. Only the soil-microbial pool's texture
response is left out; select `cMicrobialEfficiencycMic_texture` for it. This lives
in `precompute`, not `define`, since the `eff_*` fields are optimizable parameters
and `define` runs once ever.

# Turnover rate and carbon-to-nitrogen ratio

`k_c_scalar`, `CN_ratio_scalar`, and the four `*_age_scalar` fields are likewise
resolved in `precompute`: `define` only allocates the zero-initialized
`c_eco_k_base`/`CN_ratio_cVeg` arrays and the flow topology, and `precompute`
writes their actual values by pool name via `@rep_elem` (the land arrays are
immutable `SVector`s). `CASA_TAU_NON_VEG_POOLS`/`CASA_CN_ratio` (in
`poolConfigurations/CASA.jl`) carry the fixed per-pool turnover-time and
C:N-ratio data; only the scalars are optimizable.

The four vegetation-compartment pools' turnover (`cVegRootFine`, `cVegRootCoarse`,
`cVegWood`, `cVegLeaf`) is not in `CASA_TAU_NON_VEG_POOLS`: it varies by
`land.states.veg_type_name`. `define` re-keys
`CVEG_ROOTFINE_AGE_PER_VEGTYPE`/`CVEG_LEAF_AGE_PER_VEGTYPE`/
`CVEG_ROOTCOARSE_AGE_PER_VEGTYPE`/`CVEG_WOOD_AGE_PER_VEGTYPE`
(`ParamsForVegClasses.jl`) onto the experiment's resolved `vegClass`
classification via `getParamsPerVegType`, and `precompute` looks the pixel's
`veg_type_name` up in each and applies the matching `*_age_scalar` through
`getKfromTau`.

`k_c_scalar` and the four `*_age_scalar` fields declare `"year"` as their
timescale, so `getTypedModel`/`getParameters` rescale their default and bounds to
the model's configured timestep before a run starts.

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].
 - Potter, C., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003).  Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data & ecosystem  modeling 1982–1998. Global & Planetary Change, 39[3-4], 201-213.
 - Potter; C. S.; Randerson; J. T.; Field; C. B.; Matson; P. A.; Vitousek; P. M.; Mooney; H. A.  & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global  satellite & surface data. Global Biogeochemical Cycles, 7[4], 811-841.

*Versions*
 - 1.0 on 28.05.2022 [skoirala | @dr-ko]: migrate to julia
 - 1.1 on 04.09.2026 [skoirala]: allocate `c_flow_ME_vec` here; remove the dead `c_flow_MEQP_array` parameter and the transcribed `c_flow_A_array`
 - 1.2 on 09.09.2026 [skoirala]: fold `cMicrobialEfficiency_CASA`'s 8 static constants in as parameters, applied to `c_flow_ME_vec` in `define`; remove the now-duplicate `cMicrobialEfficiency_CASA` and its three per-group factors
 - 1.3 on 10.09.2026 [skoirala]: key the four `*_age_per_PFT` fields by canonical PFT name instead of position; replace with fixed named lookups plus bounded scalar multipliers
 - 1.4 on 10.09.2026 [skoirala]: port onto the working `cCycleBase_GSI_PlantForm.jl` pattern (this approach had never been run end to end): `annk` becomes `CASA_ANNK` plus `annk_scalar`; the ME-table and turnover computation move from `define` to `precompute`; replace bulk `.=`/tuple-indexed assignment with `@rep_elem` loops (`land.diagnostics` arrays are immutable `SVector`s); allocate `c_eco_k_base`
 - 1.5 on 10.09.2026 [skoirala]: move `meCASAFlowsLitter`/`meCASAFlowsSoil` here from `cMicrobialEfficiencycLit`/`cSoil`, their only caller
 - 1.6 on 10.09.2026 [skoirala]: move the `*_age_per_PFT` tables to the consolidated `vegTypeParamCatalog.jl`; the four `*_age_scalar` fields stay here, still unwired into `precompute`
 - 1.7 on 11.09.2026 [skoirala]: rename `CASA_ANNK` to `CASA_TAU_NON_VEG_POOLS` (turnover time, not rate) and `annk_scalar` to `k_c_scalar`; replace the 4-element `p_CN_ratio_cVeg` with the full-coverage `CASA_CN_ratio` table plus `CN_ratio_scalar`; freeze prior behavior as `cCycleBase_CASA_Legacy`; `define`'s `c_model` now packs `params` itself rather than a fresh instance; rename the four `*_age_scalar` fields to the `k_c_*` convention
 - 1.8 on 11.09.2026 [skoirala]: fix a pre-existing bug (never exercised end to end, see 1.4): `k_c_scalar` had no declared timescale, so turnover was never rescaled to the model's timestep; declaring `"year"` fixes it
 - 1.9 on 11.09.2026 [skoirala]: wire the four `*_age_scalar` fields into `precompute` (dead since 1.6); vegetation-compartment turnover now varies by `veg_type_name` via `getParamsPerVegType`; declare `"year"` timescale on the four scalars; freeze prior behavior as `cCycleBase_CASA_Legacy`
 - 2.0 on 15.09.2026 [skoirala]: replace the flat `c_remain` parameter with `c_remain_scalar`, following the per-vegetation-type pattern of the turnover ages above (`C_REMAIN_PER_VEGTYPE`, `getParamForVegType`)

*Created by*
 - ncarvalhais
"""
cCycleBase_CASA
