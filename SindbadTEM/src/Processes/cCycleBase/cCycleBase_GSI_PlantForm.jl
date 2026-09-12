export cCycleBase_GSI_PlantForm

#! format: off
@bounds @describe @units @timescale @with_kw struct cCycleBase_GSI_PlantForm{
    T1,  # k_c_root_scalar
    T2,  # k_c_wood_scalar
    T3,  # k_c_leaf_scalar
    T4,  # k_c_litter_scalar
    T5,  # k_c_reserve_scalar
    T6,  # k_c_soil_scalar
    T7,  # CN_ratio_scalar
    T8,  # ηH
    T9,  # ηA
    T10  # c_remain
} <: cCycleBase
    k_c_root_scalar::T1 = 1.0 | (0.25, 4) | "scalar for turnover rate of root carbon pool" | "-" | "year"
    k_c_wood_scalar::T2 = 1.0 | (0.25, 4) | "scalar for turnover rate of wood carbon pool" | "-" | "year"
    k_c_leaf_scalar::T3 = 1.0 | (0.25, 4) | "scalar for turnover rate of leaf carbon pool" | "-" | "year"
    k_c_litter_scalar::T4 = 1.0 | (0.25, 4) | "scalar for turnover rate of litter carbon pools" | "-" | "year"
    k_c_reserve_scalar::T5 = 1.0 | (0.25, 4) | "scalar for turnover rate of reserve carbon pool" | "-" | "year"
    k_c_soil_scalar::T6 = 1.0 | (0.25, 4) | "scalar for turnover rate of soil carbon pools" | "-" | "year"
    CN_ratio_scalar::T7 = 1.0 | (0.25, 4) | "scalar for the vegetation carbon-to-nitrogen ratio" | "-" | ""
    ηH::T8 = 1.0 | (0.125, 8.0) | "scaling factor for heterotrophic pools after spinup" | "" | ""
    ηA::T9 = 1.0 | (0.25, 4.0) | "scaling factor for vegetation pools after spinup" | "" | ""
    c_remain::T10 = 50.0 | (0.1, 100.0) | "remaining carbon after disturbance" | "gC/m2" | ""
end
#! format: on

function define(params::cCycleBase_GSI_PlantForm, forcing, land, helpers)
    @unpack_cCycleBase_GSI_PlantForm params
    @unpack_nt begin
        cEco ⇐ land.pools
        veg_type_class_map ⇐ land.vegClassMap
    end
    ## Instantiate variables
    C_to_N_cVeg = zero(cEco) #sujan
    c_eco_k_base = zero(cEco)
    c_eco_τ = zero(cEco)

    # one flow per declared edge of this approach, resolved against the configured
    # pool structure, rather than a transfer matrix carried as a parameter. The same
    # call keys the flows by pool-name pair and sizes the neutral flow vector, so a
    # cFlow approach reads the topology and fills in values instead of rederiving both
    (c_flow_order, c_taker, c_giver, pool_names, flow_edges, c_flow_qp_groups, c_flow_A_vec,
        c_flow_QP_vec, c_flow_ME_vec) = cFlowStructure(params, cEco, helpers)

    # Re-keyed once, at define time, onto whichever classification the experiment's
    # vegClassMap approach resolved into (the canonical vocabulary, or a grouping like
    # VegTypeCatalog_PlantForm) -- see vegTypeCatalogFor, and
    # vegQualityTraits_vegType.jl for the same pattern applied to litter chemistry.
    # No coarse-root table here: GSI has a single, undifferentiated cVegRoot pool
    # (no cVegRootCoarse), unlike CASA.
    rootfine_age_per_vegtype = vegTypeCatalogFor(CVEG_ROOTFINE_AGE_PER_VEGTYPE, typeof(veg_type_class_map))
    leaf_age_per_vegtype = vegTypeCatalogFor(CVEG_LEAF_AGE_PER_VEGTYPE, typeof(veg_type_class_map))
    wood_age_per_vegtype = vegTypeCatalogFor(CVEG_WOOD_AGE_PER_VEGTYPE, typeof(veg_type_class_map))

    c_model = params

    ## pack land variables
    @pack_nt begin
        (c_flow_order, c_taker, c_giver, pool_names, flow_edges, c_flow_qp_groups) ⇒ land.cCycleBase
        (C_to_N_cVeg, c_eco_τ, c_eco_k_base, c_flow_A_vec, c_flow_QP_vec, c_flow_ME_vec) ⇒ land.diagnostics
        (rootfine_age_per_vegtype, leaf_age_per_vegtype, wood_age_per_vegtype) ⇒ land.diagnostics
        c_model ⇒ land.models
    end
    return land
end

function precompute(params::cCycleBase_GSI_PlantForm, forcing, land, helpers)
    @unpack_cCycleBase_GSI_PlantForm params
    @unpack_nt begin
        (C_to_N_cVeg, c_eco_k_base, c_eco_τ) ⇐ land.diagnostics
        (rootfine_age_per_vegtype, leaf_age_per_vegtype, wood_age_per_vegtype) ⇐ land.diagnostics
        veg_type_name ⇐ land.states
    end

    # Select this pixel's vegetation-organ turnover from the tables define
    # re-keyed onto the active vegClassMap classification, by name rather than a
    # hardcoded per-group branch -- works for any classification the experiment
    # selects (fine canonical, or a grouping like VegTypeCatalog_PlantForm),
    # exactly like vegQualityTraits_vegType.jl.
    c_τ_organs = (;
        cVegRoot = getproperty(rootfine_age_per_vegtype, veg_type_name),
        cVegWood = getproperty(wood_age_per_vegtype, veg_type_name),
        cVegLeaf = getproperty(leaf_age_per_vegtype, veg_type_name),
        cVegReserve = TAU_DORMANT,
        cLitFast = GSI_TAU_DEFAULT.cLitFast, cLitSlow = GSI_TAU_DEFAULT.cLitSlow,
        cSoilSlow = GSI_TAU_DEFAULT.cSoilSlow, cSoilOld = GSI_TAU_DEFAULT.cSoilOld,
    )

    k_c_scalars = (;
        cVegRoot = k_c_root_scalar, cVegWood = k_c_wood_scalar,
        cVegLeaf = k_c_leaf_scalar, cVegReserve = k_c_reserve_scalar,
        cLitFast = k_c_litter_scalar, cLitSlow = k_c_litter_scalar,
        cSoilSlow = k_c_soil_scalar, cSoilOld = k_c_soil_scalar,
    )
    # c_eco_τ is written by pool name rather than by cEco position, so a structure
    # that orders or omits pools differently still gets its turnovers in the right
    # slots. Both applyPoolTable/applyPoolCNTable calls are their own functions, not
    # inline loops here, so Julia can infer this function's return type concretely
    # (see applyPoolTable's docstring, poolConfigurations/poolConfigurations.jl).
    c_eco_τ = applyPoolTable(c_eco_τ, c_τ_organs, k_c_scalars, helpers)
    C_to_N_cVeg = applyPoolCNTable(C_to_N_cVeg, GSI_CN_ratio, CN_ratio_scalar, helpers)
    for i ∈ eachindex(c_eco_k_base)
        tmp = c_eco_τ[i]
        @rep_elem tmp ⇒ (c_eco_k_base, i)
    end

    ## pack land variables
    @pack_nt begin
        (C_to_N_cVeg, c_eco_τ, c_eco_k_base, ηA, ηH) ⇒ land.diagnostics
        c_remain ⇒ land.states
        k_c_scalars ⇒ land.cCycleBase
    end
    return land
end

poolConfiguration(::Type{<:cCycleBase_GSI_PlantForm}) = CarbonPoolsGSI
cFlowEdges(::Type{<:cCycleBase_GSI_PlantForm}) = GSI_FLOW_EDGES
purpose(::Type{cCycleBase_GSI_PlantForm}) = "Same as GSI, additionally allowing for scaling of turnover parameters based on plant forms."

@doc """

$(getModelDocString(cCycleBase_GSI_PlantForm))

---

# Extended help

Reads `land.states.veg_type_name` and looks its vegetation-organ turnover up in tables
`define` re-keyed (via `vegTypeCatalogFor`) from `ParamsForVegClasses.jl`'s
`CVEG_ROOTFINE_AGE_PER_VEGTYPE`/`CVEG_WOOD_AGE_PER_VEGTYPE`/
`CVEG_LEAF_AGE_PER_VEGTYPE` onto whichever classification the experiment's
`vegClassMap` approach resolved into -- any classification works, not just
`VegTypeCatalog_PlantForm`, exactly like `vegQualityTraits_vegType.jl`. Turnover
is `k = (1.0 / turnover_time) * scalar`, `scalar` being one of the six
`k_c_*_scalar` fields (shared across pools that don't get an individual one:
`k_c_litter_scalar` for both litter pools, `k_c_soil_scalar` for both soil pools).
`cVegReserve` stays `TAU_DORMANT` and `cLitFast`/`cLitSlow`/`cSoilSlow`/`cSoilOld`
stay fixed at `GSI_TAU_DEFAULT`'s values (`poolConfigurations/GSI.jl`), neither
being vegetation-type dependent. The vegetation carbon-to-nitrogen ratio works the
same way it always has, against `GSI_CN_ratio` and `CN_ratio_scalar`. Both loops
are generic over whatever pools the respective table covers, rather than one
hand-written loop per pool. `k_c_scalars`, the per-pool-name scalar lookup the
turnover loop reads, is also packed into `land.cCycleBase`, alongside the flow
topology already stored there.

The six `k_c_*_scalar` fields declare `"year"` as their timescale, not the
per-vegtype tables themselves (plain `const`s, outside the parameter-metadata
system that timescale conversion keys off). `getTypedModel`/`getParameters`
(`SindbadTEM/src/Utils.jl`, `src/Setup/setupParameters.jl`) rescale any
`"year"`-timescale field's default and bounds to the model's actual configured
timestep before a run starts -- e.g. a `k_c_root_scalar` default of `1.0` becomes
`1/365` for a daily model -- so `turnover_time` can stay expressed in years while
`(1.0/turnover_time) * scalar` still comes out already correctly scaled to the
model's own timestep. The old, now-removed `c_τ_tree`/
`c_τ_shrub`/`c_τ_herb`/`c_τ_LitFast`/`c_τ_LitSlow`/`c_τ_SoilSlow`/`c_τ_SoilOld`
fields (see `cCycleBase_GSI_PlantForm_Legacy`) carried `"year"` themselves, not
their scalars -- the annotation moved here because the absolute values it used to
sit on no longer exist as struct fields at all.

**Calibration-space note**: before this table-driven design, `c_τ_tree`/
`c_τ_shrub`/`c_τ_herb` were themselves bounded, independently-optimizable fields
(12 numbers: 4 organs × 3 forms), on top of which the `*_scalar` fields applied a
further, generic adjustment. The per-vegtype tables' entries are fixed data, not
parameters, so only the six shared scalars remain optimizable now -- a real
reduction in calibration degrees of freedom, not a pure refactor. The frozen
pre-change behavior, with the old per-plant-form bounded fields intact, is
preserved unchanged as `cCycleBase_GSI_PlantForm_Legacy`.

*References*
 - Potter; C. S.; J. T. Randerson; C. B. Field; P. A. Matson; P. M.  Vitousek; H. A. Mooney; & S. A. Klooster. 1993. Terrestrial ecosystem  production: A process model based on global satellite & surface data.  Global Biogeochemical Cycles. 7: 811-841.

*Versions*
 - 1.0 on 28.02.2020 [skoirala | @dr-ko]
 - 1.1 on 04.09.2026 [skoirala]: c_flow_ME_vec allocated here alongside c_flow_A_vec and c_flow_QP_vec
 - 1.2 on 10.09.2026 [skoirala]: reads `land.states.veg_type_name` instead of
   `land.states.plant_form`, following the merge of the `PFT`/`plantForm`
   processes into `vegTypes`; branch structure and field names unchanged
 - 1.3 on 11.09.2026 [skoirala]: `c_τ_tree`/`c_τ_shrub`/`c_τ_herb`,
   `c_τ_LitFast`/`c_τ_LitSlow`/`c_τ_SoilSlow`/`c_τ_SoilOld`, and the 4-element
   `p_C_to_N_cVeg` vector removed as struct fields; turnover and C:N now read
   from the centralized `GSI_TAU_PLANTFORM`/`GSI_CN_ratio` tables
   (`poolConfigurations/GSI.jl`) via `GSI_TAU_PLANTFORM[veg_type_name]` and a generic
   per-pool-name loop, replacing the hardcoded
   `if veg_type_name == :tree ... elseif ...` branch and `zero_c_τ_pf` fallback
   (`:unknown` is now just another `GSI_TAU_PLANTFORM` entry); `k_c_*_scalar`
   naming replaces `c_τ_*_scalar` throughout, matching the convention now shared
   with `cCycleBase_CASA`/`cCycleBase_GSI`. Dead `get_c_τ` helper removed. The
   frozen pre-change behavior is preserved, unchanged, as
   `cCycleBase_GSI_PlantForm_Legacy`. Also: `define`'s `c_model` now packs
   `params` itself rather than a freshly constructed `cCycleBase_GSI_PlantForm()`,
   since `land.models` is only ever read for its type (pure dispatch), so the
   fresh instance only threw away whatever values `params` actually held for no
   benefit. `k_c_scalars` is now also packed into `land.cCycleBase`, not just
   used locally to build `c_eco_τ`.
 - 1.4 on 11.09.2026 [skoirala]: fixed a real bug from 1.3's centralization: the
   6 `k_c_*_scalar` fields had `""` (no) declared timescale, and neither did
   `GSI_TAU_PLANTFORM`'s entries (a plain `const`), so unlike the old `c_τ_tree`/
   `c_τ_shrub`/`c_τ_herb`/`c_τ_LitFast`/etc. fields they replaced (declared
   `"year"`), nothing rescaled the year-based turnover time to the model's
   actual configured timestep -- at a daily model, every turnover rate came out
   roughly 365x too fast. Declaring the scalars `"year"` instead fixes it, since
   `getTypedModel`/`getParameters` rescale a `"year"`-timescale field's default
   (and bounds) to the model's timestep before a run starts. Verified against
   `cCycleBase_GSI_PlantForm_Legacy` at a daily timestep: turnover now matches
   to floating-point precision on every pool.
 - 1.5 on 11.09.2026 [skoirala]: `GSI_TAU_PLANTFORM[veg_type_name]` replaced by a
   runtime lookup into `CVEG_ROOTFINE_AGE_PER_VEGTYPE`/
   `CVEG_WOOD_AGE_PER_VEGTYPE`/`CVEG_LEAF_AGE_PER_VEGTYPE`
   (`vegTypeParamCatalog.jl`), re-keyed in `define` onto the active `vegClassMap`
   classification via `vegTypeCatalogFor` and looked up by `veg_type_name` in
   `precompute` -- the same pattern `vegQualityTraits_vegType.jl` uses, and
   no longer tied to `VegTypeCatalog_PlantForm` specifically. `GSI_TAU_PLANTFORM`
   itself is removed (`poolConfigurations/GSI.jl`), fully superseded. Note: this
   approach now resolves vegetation-organ turnover the same way plain
   `cCycleBase_GSI` does (see its own 1.4 entry), so the two are functionally
   near-identical going forward; kept separate rather than merged, pending a
   deliberate decision on whether to do so.

*Created by*
 - ncarvalhais
"""
cCycleBase_GSI_PlantForm
