export cCycleBase_GSI

#! format: off
@bounds @describe @units @timescale @with_kw struct cCycleBase_GSI{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10} <: cCycleBase
    k_c_root_scalar::T1 = 1.0 | (0.25, 4.0) | "scalar for turnover rate of root carbon pool" | "-" | "year"
    k_c_wood_scalar::T2 = 1.0 | (0.25, 4.0) | "scalar for turnover rate of wood carbon pool" | "-" | "year"
    k_c_leaf_scalar::T3 = 1.0 | (0.25, 4.0) | "scalar for turnover rate of leaf carbon pool" | "-" | "year"
    k_c_reserve_scalar::T4 = 1.0 | (0.25, 4.0) | "scalar for turnover rate of reserve carbon pool" | "-" | "year"
    k_c_litter_scalar::T5 = 1.0 | (0.25, 4.0) | "scalar for turnover rate of litter carbon pools" | "-" | "year"
    k_c_soil_scalar::T6 = 1.0 | (0.25, 4.0) | "scalar for turnover rate of soil carbon pools" | "-" | "year"
    CN_ratio_scalar::T7 = 1.0 | (0.25, 4.0) | "scalar for the vegetation carbon-to-nitrogen ratio" | "-" | ""
    ηH::T8 = 1.0 | (0.01, 100.0) | "scaling factor for heterotrophic pools after spinup" | "" | ""
    ηA::T9 = 1.0 | (0.01, 100.0) | "scaling factor for vegetation pools after spinup" | "" | ""
    c_remain::T10 = 10.0 | (0.1, 100.0) | "remaining carbon after disturbance" | "" | ""
end
#! format: on

function define(params::cCycleBase_GSI, forcing, land, helpers)
    @unpack_cCycleBase_GSI params
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

function precompute(params::cCycleBase_GSI, forcing, land, helpers)
    @unpack_cCycleBase_GSI params
    @unpack_nt begin
        (C_to_N_cVeg, c_eco_k_base, c_eco_τ) ⇐ land.diagnostics
        (rootfine_age_per_vegtype, leaf_age_per_vegtype, wood_age_per_vegtype) ⇐ land.diagnostics
        veg_type_name ⇐ land.states
    end

    ## replace values
    # cVegRoot/cVegWood/cVegLeaf turnover now varies by land.states.veg_type_name,
    # looked up in the tables define re-keyed from ParamsForVegClasses.jl; the
    # litter/soil/reserve pools stay fixed, from GSI_TAU_DEFAULT, since they are
    # not vegetation-type dependent. c_eco_τ is written by pool name rather than
    # by cEco position, so a structure that orders or omits pools differently
    # still gets its turnovers in the right slots. Both applyPoolTable/
    # applyPoolCNTable calls are generic over whatever pools the table covers,
    # rather than one hand-written loop per pool -- and live as their own
    # functions, not inline loops here, so Julia can infer this function's return
    # type concretely (see applyPoolTable's docstring,
    # poolConfigurations/poolConfigurations.jl).
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

poolConfiguration(::Type{<:cCycleBase_GSI}) = CarbonPoolsGSI
cFlowEdges(::Type{<:cCycleBase_GSI}) = GSI_FLOW_EDGES
purpose(::Type{cCycleBase_GSI}) = "Structure and properties of the carbon cycle components as needed for a dynamic phenology-based carbon cycle in the GSI approach."

@doc """

$(getModelDocString(cCycleBase_GSI))

---

# Extended help

Turnover for the four vegetation organs (root, wood, leaf, reserve) and the four
litter/soil pools is `k = (1.0 / turnover_time) * scalar`, where `scalar` is one of
the six `k_c_*_scalar` fields, shared across pools that don't get their own
individual scalar (`k_c_litter_scalar` for both litter pools, `k_c_soil_scalar` for
both soil pools). `turnover_time` for `cVegRoot`/`cVegWood`/`cVegLeaf` now varies by
`land.states.veg_type_name`: `define` re-keys `CVEG_ROOTFINE_AGE_PER_VEGTYPE`/
`CVEG_WOOD_AGE_PER_VEGTYPE`/`CVEG_LEAF_AGE_PER_VEGTYPE` (`ParamsForVegClasses.jl`)
onto whichever classification the experiment's `vegClassMap` approach resolved into
(`vegTypeCatalogFor`), and `precompute` looks the current pixel's `veg_type_name` up in
each -- the same pattern `vegQualityTraits_vegType.jl` uses for litter chemistry.
`cVegReserve` stays `TAU_DORMANT` (not vegetation-type dependent), and
`cLitFast`/`cLitSlow`/`cSoilSlow`/`cSoilOld` stay fixed at `GSI_TAU_DEFAULT`'s
values (`poolConfigurations/GSI.jl`, also not vegetation-type dependent). The
vegetation carbon-to-nitrogen ratio works the same way it always has, against
`GSI_CN_ratio` and `CN_ratio_scalar`. Both loops are generic over whatever pools
the respective table covers, rather than one hand-written loop per pool.
`k_c_scalars`, the per-pool-name scalar lookup the turnover loop reads, is also
packed into `land.cCycleBase`, alongside the flow topology already stored there.

The six `k_c_*_scalar` fields declare `"year"` as their timescale, not the
per-vegtype tables themselves (plain `const`s, outside the parameter-metadata
system that timescale conversion keys off). `getTypedModel`/`getParameters` (`SindbadTEM/src/Utils.jl`,
`src/Setup/setupParameters.jl`) rescale any `"year"`-timescale field's default and
bounds to the model's actual configured timestep before a run starts -- e.g. a
`k_c_root_scalar` default of `1.0` becomes `1/365` for a daily model -- so
`turnover_time` can stay expressed in years while `(1.0/turnover_time) * scalar`
still comes out already correctly scaled to the model's own timestep, exactly
reproducing what putting `"year"` directly on the old, now-removed absolute-rate
fields (`c_τ_Root` etc., see `cCycleBase_GSI_Legacy`) used to do.

*References*
 - Potter; C. S.; J. T. Randerson; C. B. Field; P. A. Matson; P. M.  Vitousek; H. A. Mooney; & S. A. Klooster. 1993. Terrestrial ecosystem  production: A process model based on global satellite & surface data.  Global Biogeochemical Cycles. 7: 811-841.

*Versions*
 - 1.0 on 28.02.2020 [skoirala | @dr-ko]
 - 1.1 on 04.09.2026 [skoirala]: c_flow_ME_vec allocated here alongside c_flow_A_vec and c_flow_QP_vec
 - 1.2 on 11.09.2026 [skoirala]: the 8 independently-bounded turnover fields and
   the 4-element `p_C_to_N_cVeg` vector replaced by 6 shared `k_c_*_scalar` fields
   and `CN_ratio_scalar`, applied against the centralized `GSI_TAU_DEFAULT`/
   `GSI_CN_ratio` tables (`poolConfigurations/GSI.jl`) via a generic per-pool-name
   loop; matches the field shape `cCycleBase_GSI_PlantForm` already had. Default
   turnover is unchanged for root/leaf/reserve/litter/soil, and changes slightly
   for wood (`k=0.02`, was `0.03`) since the new shared base is tree's turnover
   time (50 years) rather than this approach's own prior default (33.3 years). The
   frozen pre-change behavior is preserved, unchanged, as `cCycleBase_GSI_Legacy`.
   Also: `define`'s `c_model` now packs `params` itself rather than a freshly
   constructed `cCycleBase_GSI()`, since `land.models` is only ever read for its
   type (pure dispatch), so the fresh instance only threw away whatever values
   `params` actually held for no benefit. `k_c_scalars` is now also packed into
   `land.cCycleBase`, not just used locally to build `c_eco_τ`.
 - 1.3 on 11.09.2026 [skoirala]: fixed a real bug from 1.2's centralization: the
   6 `k_c_*_scalar` fields had `""` (no) declared timescale, so unlike the old
   `c_τ_Root` etc. fields they replaced (declared `"year"`), nothing rescaled
   `GSI_TAU_DEFAULT`'s year-based turnover time to the model's actual configured
   timestep -- at a daily model, every turnover rate came out roughly 365x too
   fast. Declaring the scalars `"year"` instead fixes it, since
   `getTypedModel`/`getParameters` rescale a `"year"`-timescale field's default
   (and bounds) to the model's timestep before a run starts, the same mechanism
   the old fields relied on. Verified against `cCycleBase_GSI_Legacy` at a daily
   timestep: turnover now matches to floating-point precision (root/leaf/
   reserve/litter/soil pools) or by exactly the deliberate `0.02`-vs-`0.03`
   ratio from 1.2 (wood).
 - 1.4 on 11.09.2026 [skoirala]: `cVegRoot`/`cVegWood`/`cVegLeaf` turnover no
   longer reads the fixed `GSI_TAU_DEFAULT` values -- `define` re-keys
   `CVEG_ROOTFINE_AGE_PER_VEGTYPE`/`CVEG_WOOD_AGE_PER_VEGTYPE`/
   `CVEG_LEAF_AGE_PER_VEGTYPE` (`vegTypeParamCatalog.jl`) onto the experiment's
   active `vegClassMap` classification and `precompute` looks the pixel's
   `land.states.veg_type_name` up in each, so this approach -- previously documented
   as having "no plant-form distinction" -- now varies vegetation-organ
   turnover by vegetation type like `cCycleBase_GSI_PlantForm` did, just at
   finer granularity. `cVegReserve`/litter/soil turnover is unchanged, still
   fixed from `GSI_TAU_DEFAULT`.
 - ncarvalhais
"""
cCycleBase_GSI
