export cCycleBase_MGMT 

#! format: off
@bounds @describe @units @timescale @with_kw struct cCycleBase_MGMT{
    T1,  # k_c_root_scalar
    T2,  # k_c_wood_scalar
    T3,  # k_c_leaf_scalar
    T4,  # k_c_reserve_scalar
    T5,  # k_c_litfast_scalar
    T6,  # k_c_litslow_scalar
    T7,  # k_c_soilslow_scalar
    T8,  # k_c_soilold_scalar
    T9,  # k_c_products_wood_scalar
    T10, # k_c_products_crop_scalar
    T11, # α_k_cVeg
    T12, # α_k_cLit
    T13, # α_k_cSoil
    T14, # k_c_allProducts_scalar
    T15, # CN_ratio_scalar
    T16, # ηH
    T17, # ηA
    T18, # c_remain_scalar
    T19  # k_hilo_scalar
} <: cCycleBase
    k_c_root_scalar::T1 = 1.0 | (0.25, 4) | "scalar for turnover rate of root carbon pool" | "-" | "year"
    k_c_wood_scalar::T2 = 1.0 | (0.25, 4) | "scalar for turnover rate of wood carbon pool" | "-" | "year"
    k_c_leaf_scalar::T3 = 1.0 | (0.25, 4) | "scalar for turnover rate of leaf carbon pool" | "-" | "year"
    k_c_reserve_scalar::T4 = 1.0 | (0.25, 4) | "scalar for turnover rate of reserve carbon pool" | "-" | "year"

    k_c_litfast_scalar::T5 = 1.0 | (0.25, 4) | "scalar for turnover rate of litter fast carbon pool" | "-" | "year"
    k_c_litslow_scalar::T6 = 1.0 | (0.25, 4) | "scalar for turnover rate of litter slow carbon pool" | "-" | "year"
    k_c_soilslow_scalar::T7 = 1.0 | (0.25, 4) | "scalar for turnover rate of soil slow carbon pool" | "-" | "year"
    k_c_soilold_scalar::T8 = 1.0 | (0.25, 4) | "scalar for turnover rate of soil old carbon pool" | "-" | "year"

    k_c_products_wood_scalar::T9 = 1.0 | (0.25, 4) | "scalar for turnover rate of harvested wood product carbon pool" | "-" | "year"
    k_c_products_crop_scalar::T10 = 1.0 | (0.25, 4) | "scalar for turnover rate of harvested crop product carbon pool" | "-" | "year"

    α_k_cVeg::T11 = 1.0 | (0.25, 4.0) | "scalar for turnover rate of all vegetation carbon pools; it has no timescale, since it scales the original pool level k." | "-" | ""
    α_k_cLit::T12 = 1.0 | (0.25, 4) | "scalar for turnover rate of all litter carbon pools; it has no timescale, since it scales the original pool level k." | "-" | ""
    α_k_cSoil::T13 = 1.0 | (0.25, 4) | "scalar for turnover rate of all soil carbon pools; it has no timescale, since it scales the original pool level k." | "-" | ""
    k_c_allProducts_scalar::T14 = 1.0 | (0.25, 4) | "scalar for turnover rate of all wood product carbon pools; it has no timescale, since it scales the original pool level k." | "-" | ""
    
    CN_ratio_scalar::T15 = 1.0 | (0.25, 4) | "scalar for the vegetation carbon-to-nitrogen ratio" | "-" | ""
    ηH::T16 = 1.0 | (0.125, 8.0) | "scaling factor for heterotrophic pools after spinup" | "" | ""
    ηA::T17 = 1.0 | (0.25, 4.0) | "scaling factor for vegetation pools after spinup" | "" | ""
    c_remain_scalar::T18 = 1.0 | (0.1, 10.0) | "scalar for the per-vegetation-type minimum remaining carbon after disturbance" | "-" | ""
    k_hilo_scalar::T19 = 1.0 | (-Inf, Inf) | "timescale factor for split of high and low turnover rates" | "-" | "year"
end
#! format: on

function define(params::cCycleBase_MGMT , forcing, land, helpers)
    @unpack_cCycleBase_MGMT  params
    @unpack_nt begin
        cEco ⇐ land.pools
        veg_type_class_map ⇐ land.vegClass
    end
    ## Instantiate variables
    CN_ratio_cVeg = zero(cEco) #sujan
    c_eco_k_base = zero(cEco)
    c_eco_τ = zero(cEco)

    # one flow per declared edge of this approach, resolved against the configured
    # pool structure, rather than a transfer matrix carried as a parameter. The same
    # call keys the flows by pool-name pair and sizes the neutral flow vector, so a
    # cFlow approach reads the topology and fills in values instead of rederiving both
    (c_flow_order, c_taker, c_giver, pool_names, flow_edges, c_flow_taker_turnover_rank, c_flow_A_vec,
        c_flow_QP_vec, c_flow_ME_vec) = cFlowStructure(params, cEco, helpers)

    # Re-keyed once, at define time, onto whichever classification the experiment's
    # vegClass approach resolved into (the canonical vocabulary, or a grouping like
    # Classification_PlantForm) -- see getParamsPerVegType, and
    # vegQualityTraits_vegType.jl for the same pattern applied to litter chemistry.
    # No coarse-root table here: GSI has a single, undifferentiated cVegRoot pool
    # (no cVegRootCoarse), unlike CASA.
    rootfine_age_per_vegtype = getParamsPerVegType(CVEG_ROOTFINE_AGE_PER_VEGTYPE, typeof(veg_type_class_map))
    leaf_age_per_vegtype = getParamsPerVegType(CVEG_LEAF_AGE_PER_VEGTYPE, typeof(veg_type_class_map))
    wood_age_per_vegtype = getParamsPerVegType(CVEG_WOOD_AGE_PER_VEGTYPE, typeof(veg_type_class_map))
    c_remain_per_vegtype = getParamsPerVegType(C_REMAIN_PER_VEGTYPE, typeof(veg_type_class_map))

    c_model = params

    zix_cNonVeg, zix_cNatural, zix_cHeterotrophic, zix_cProducts = cCycleBaseZixGroups(helpers)

    # k_hilo_lit_split = (one(TAU_HILO_LIT_SPLIT) / eltype(c_eco_k_base)(TAU_HILO_LIT_SPLIT)) * α_k_cVeg # this is a place holder to convert TAU_HILO_LIT_SPLIT to k time units...

    ## pack land variables
    @pack_nt begin
        # (c_flow_order, c_taker, c_giver, pool_names, flow_edges, c_flow_taker_turnover_rank, k_hilo_lit_split) ⇒ land.cCycleBase
        (c_flow_order, c_taker, c_giver, pool_names, flow_edges, c_flow_taker_turnover_rank) ⇒ land.cCycleBase
        (CN_ratio_cVeg, c_eco_τ, c_eco_k_base, c_flow_A_vec, c_flow_QP_vec, c_flow_ME_vec) ⇒ land.diagnostics
        (rootfine_age_per_vegtype, leaf_age_per_vegtype, wood_age_per_vegtype) ⇒ land.diagnostics
        c_remain_per_vegtype ⇒ land.diagnostics
        c_model ⇒ land.models
        (zix_cNonVeg, zix_cNatural, zix_cHeterotrophic, zix_cProducts) ⇒ land.cCycleBase
    end
    return land
end

function precompute(params::cCycleBase_MGMT , forcing, land, helpers)
    @unpack_cCycleBase_MGMT  params
    @unpack_nt begin
        (CN_ratio_cVeg, c_eco_k_base, c_eco_τ) ⇐ land.diagnostics
        (rootfine_age_per_vegtype, leaf_age_per_vegtype, wood_age_per_vegtype) ⇐ land.diagnostics
        c_remain_per_vegtype ⇐ land.diagnostics
        (c_flow_order, c_giver, c_taker, c_flow_taker_turnover_rank) ⇐ land.cCycleBase
        veg_type_name ⇐ land.states
    end

    # Select this pixel's vegetation-compartment turnover from the tables define
    # re-keyed onto the active vegClass classification, by name rather than a
    # hardcoded per-group branch. cProductsWood/cProductsCrop are appended fixed
    # (not vegetation-type dependent, see MGMT_PRODUCTS_TAU's docstring) so they
    # still flow through the same generic loop as every other pool here.
    c_τ_default = (;
        cVegRoot = getproperty(rootfine_age_per_vegtype, veg_type_name),
        cVegWood = getproperty(wood_age_per_vegtype, veg_type_name),
        cVegLeaf = getproperty(leaf_age_per_vegtype, veg_type_name),
        cVegReserve = TAU_DORMANT,
        cLitFast = GSI_TAU_DEFAULT.cLitFast, cLitSlow = GSI_TAU_DEFAULT.cLitSlow,
        cSoilSlow = GSI_TAU_DEFAULT.cSoilSlow, cSoilOld = GSI_TAU_DEFAULT.cSoilOld,
        cProductsWood = MGMT_PRODUCTS_TAU.cProductsWood, cProductsCrop = MGMT_PRODUCTS_TAU.cProductsCrop,
    )

    k_c_scalars = (;
        cVegRoot = k_c_root_scalar * α_k_cVeg, 
        cVegWood = k_c_wood_scalar * α_k_cVeg,
        cVegLeaf = k_c_leaf_scalar * α_k_cVeg, 
        cVegReserve = k_c_reserve_scalar * α_k_cVeg,
        cLitFast = k_c_litfast_scalar * α_k_cLit, 
        cLitSlow = k_c_litslow_scalar * α_k_cLit,
        cSoilSlow = k_c_soilslow_scalar * α_k_cSoil, 
        cSoilOld = k_c_soilold_scalar * α_k_cSoil,
        cProductsWood = k_c_products_wood_scalar * k_c_allProducts_scalar, 
        cProductsCrop = k_c_products_crop_scalar * k_c_allProducts_scalar,
    )

    # c_eco_τ is written by pool name rather than by cEco position, so a structure
    # that orders or omits pools differently still gets its turnovers in the right
    # slots. Both getKfromTau/getCNfromParams calls are their own functions, not
    # inline loops here, so Julia can infer this function's return type concretely
    # (see getKfromTau's docstring, poolConfigurations/poolConfigurations.jl).
    CN_ratio_cVeg = getCNfromParams(CN_ratio_cVeg, GSI_CN_ratio, CN_ratio_scalar, helpers)
    c_eco_k_base = getKfromTau(c_eco_τ, c_τ_default, k_c_scalars, helpers)

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
        (CN_ratio_cVeg, c_eco_τ, c_eco_k_base, ηA, ηH) ⇒ land.diagnostics
        c_remain ⇒ land.states
        k_c_scalars ⇒ land.cCycleBase
        (c_flow_taker_turnover_rank, k_hilo_lit_split) ⇒ land.cCycleBase
    end
    return land
end

poolConfiguration(::Type{<:cCycleBase_MGMT }) = MGMT
purpose(::Type{cCycleBase_MGMT }) = "Same as GSI, additionally allowing for scaling of turnover parameters based on plant forms."

@doc """

$(getModelDocString(cCycleBase_MGMT ))

---

# Extended help

Reads `land.states.veg_type_name` and looks its vegetation-compartment turnover up
in tables `define` re-keys (via `getParamsPerVegType`) from
`ParamsForVegClasses.jl`'s `CVEG_ROOTFINE_AGE_PER_VEGTYPE`/
`CVEG_WOOD_AGE_PER_VEGTYPE`/`CVEG_LEAF_AGE_PER_VEGTYPE` onto the experiment's
resolved `vegClass` classification. Turnover is
`k = (1.0 / turnover_time) * scalar`, `scalar` being one of the eight
`k_c_*_scalar` fields (shared across pools without an individual one:
`α_k_cLit` for both litter pools, `α_k_cSoil` for both soil pools).
`cVegReserve` stays `TAU_DORMANT` and `cLitFast`/`cLitSlow`/`cSoilSlow`/
`cSoilOld` stay fixed at `GSI_TAU_DEFAULT`'s values, neither being
vegetation-type dependent. `k_c_products_wood_scalar`/`k_c_products_crop_scalar`
scale `cProductsWood`/`cProductsCrop` through the same generic loop, with their
fixed turnover time (`MGMT_PRODUCTS_TAU`) appended to the per-vegtype table at
the `precompute` call site, since harvested-product decay does not depend on
vegetation type. The vegetation carbon-to-nitrogen ratio is unaffected, against
`GSI_CN_ratio` and `CN_ratio_scalar` as before.

The eight `k_c_*_scalar` fields declare `"year"` as their timescale, so
`getTypedModel`/`getParameters` rescale their default and bounds to the model's
configured timestep before a run starts.

**Calibration-space note**: before this table-driven design, `c_τ_tree`/
`c_τ_shrub`/`c_τ_herb` were themselves bounded, independently-optimizable fields
(12 numbers), and `c_τ_cProductsWood`/`c_τ_cProductsCrop` were independently
bounded too. The per-vegtype tables are fixed data, not parameters, so only the
eight shared scalars remain optimizable now, a real reduction in calibration
degrees of freedom. The frozen pre-change behavior is preserved unchanged as
`cCycleBase_MGMT_Legacy`.

*References*
 - Potter; C. S.; J. T. Randerson; C. B. Field; P. A. Matson; P. M.  Vitousek; H. A. Mooney; & S. A. Klooster. 1993. Terrestrial ecosystem  production: A process model based on global satellite & surface data.  Global Biogeochemical Cycles. 7: 811-841.

*Versions*
 - 1.0 on 28.02.2020 [skoirala | @dr-ko]
 - 1.1 on 04.09.2026 [skoirala]: allocate `c_flow_ME_vec` here alongside `c_flow_A_vec` and `c_flow_QP_vec`
 - 1.2 on 10.09.2026 [skoirala]: read `land.states.veg_type_name` instead of `land.states.plant_form`, following the merge of the `PFT`/`plantForm` processes into `vegTypes`
 - 1.3 on 11.09.2026 [skoirala]: remove `c_τ_tree`/`c_τ_shrub`/`c_τ_herb`, `c_τ_LitFast`/`c_τ_LitSlow`/`c_τ_SoilSlow`/`c_τ_SoilOld`, and the 4-element `p_CN_ratio_cVeg` vector as struct fields; read turnover and C:N from the centralized `GSI_TAU_PLANTFORM`/`GSI_CN_ratio` tables via a generic per-pool-name loop, replacing the hardcoded branch; rename `c_τ_*_scalar` to `k_c_*_scalar`; remove the dead `get_c_τ` helper; freeze prior behavior as `cCycleBase_MGMT_Legacy`
 - 1.4 on 11.09.2026 [skoirala]: remove `c_τ_cProductsWood`/`c_τ_cProductsCrop` as struct fields, replaced by `k_c_products_wood_scalar`/`k_c_products_crop_scalar`; move their turnover times into `MGMT_TAU`, read through the same generic loop as every other pool; `define`'s `c_model` now packs `params` itself rather than a fresh instance; pack `k_c_scalars` into `land.cCycleBase`
 - 1.5 on 11.09.2026 [skoirala]: fix a bug from 1.3/1.4: the 8 `k_c_*_scalar` fields had no declared timescale, so turnover was never rescaled to the model's timestep; declaring `"year"` fixes it
 - 1.6 on 11.09.2026 [skoirala]: replace `MGMT_TAU[veg_type_name]` with a runtime lookup into `CVEG_ROOTFINE_AGE_PER_VEGTYPE`/`CVEG_WOOD_AGE_PER_VEGTYPE`/`CVEG_LEAF_AGE_PER_VEGTYPE`, re-keyed onto the active `vegClass` classification, with `cProductsWood`/`cProductsCrop` appended from the new fixed `MGMT_PRODUCTS_TAU`
 - 1.7 on 15.09.2026 [skoirala]: replace the flat `c_remain` parameter with `c_remain_scalar`, following the per-vegetation-type pattern of the turnover ages above

*Created by*
 - ncarvalhais
"""
cCycleBase_MGMT 
