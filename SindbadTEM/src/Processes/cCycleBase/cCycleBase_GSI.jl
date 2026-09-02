export cCycleBase_GSI, adjustPackPoolComponents

#! format: off
@bounds @describe @units @timescale @with_kw struct cCycleBase_GSI{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13} <: cCycleBase
    c_τ_Root::T1 = 1.0 | (0.05, 3.3) | "turnover rate of root carbon pool" | "year-1" | "year"
    c_τ_Wood::T2 = 0.03 | (0.001, 10.0) | "turnover rate of wood carbon pool" | "year-1" | "year"
    c_τ_Leaf::T3 = 1.0 | (0.05, 10.0) | "turnover rate of leaf carbon pool" | "year-1" | "year"
    c_τ_Reserve::T4 = 1.0e-11 | (1.0e-12, 1.0) | "Reserve does not respire, but has a small value to avoid  numerical error" | "year-1" | "year"
    c_τ_LitFast::T5 = 14.8 | (0.5, 148.0) | "turnover rate of fast litter (leaf litter) carbon pool" | "year-1" | "year"
    c_τ_LitSlow::T6 = 3.9 | (0.39, 39.0) | "turnover rate of slow litter carbon (wood litter) pool" | "year-1" | "year"
    c_τ_SoilSlow::T7 = 0.2 | (0.02, 2.0) | "turnover rate of slow soil carbon pool" | "year-1" | "year"
    c_τ_SoilOld::T8 = 0.0045 | (0.00045, 0.045) | "turnover rate of old soil carbon pool" | "year-1" | "year"
    c_flow_A_array::T9 = Float64.([
                     -1.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0
                     0.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0
                     0.0 0.0 -1.0 1.0 0.0 0.0 0.0 0.0
                     1.0 0.0 1.0 -1.0 0.0 0.0 0.0 0.0
                     1.0 0.0 1.0 1.0 -1.0 0.0 0.0 0.0
                     0.0 1.0 0.0 0.0 0.0 -1.0 0.0 0.0
                     0.0 0.0 0.0 0.0 1.0 1.0 -1.0 0.0
                     0.0 0.0 0.0 0.0 0.0 0.0 1.0 -1.0
                 ]) | (-Inf, Inf) | "Transfer matrix for carbon at ecosystem level" | "" | ""
    p_C_to_N_cVeg::T10 = Float64.([25.0, 260.0, 260.0, 10.0]) | (-Inf, Inf) | "carbon to nitrogen ratio in vegetation pools" | "gC/gN" | ""
    ηH::T11 = 1.0 | (0.01, 100.0) | "scaling factor for heterotrophic pools after spinup" | "" | ""
    ηA::T12 = 1.0 | (0.01, 100.0) | "scaling factor for vegetation pools after spinup" | "" | ""
    c_remain::T13 = 10.0 | (0.1, 100.0) | "remaining carbon after disturbance" | "" | ""
end
#! format: on

function define(params::cCycleBase_GSI, forcing, land, helpers)
    @unpack_cCycleBase_GSI params
    @unpack_nt begin
        cEco ⇐ land.pools
        (z_zero, o_one) ⇐ land.constants
    end
    ## Instantiate variables
    C_to_N_cVeg = zero(cEco) #sujan
    # C_to_N_cVeg[getZix(land.pools.cVeg, helpers.pools.zix.cVeg)] .= p_C_to_N_cVeg
    c_eco_k_base = zero(cEco)
    c_eco_τ = zero(cEco)

    # if there is flux order check that is consistent
    c_flow_order = Tuple(collect(1:length(findall(>(z_zero), c_flow_A_array))))
    c_taker = Tuple([ind[1] for ind ∈ findall(>(z_zero), c_flow_A_array)])
    c_giver = Tuple([ind[2] for ind ∈ findall(>(z_zero), c_flow_A_array)])

    c_model = cCycleBase_GSI()

    ## pack land variables
    @pack_nt begin
        c_flow_A_array ⇒ land.diagnostics
        (c_flow_order, c_taker, c_giver) ⇒ land.constants
        (C_to_N_cVeg, c_eco_τ, c_eco_k_base) ⇒ land.diagnostics
        c_model ⇒ land.models
    end
    return land
end

function precompute(params::cCycleBase_GSI, forcing, land, helpers)
    @unpack_cCycleBase_GSI params
    @unpack_nt begin
        (C_to_N_cVeg, c_eco_k_base, c_eco_τ) ⇐ land.diagnostics
        (z_zero, o_one) ⇐ land.constants
    end

    ## replace values
    @rep_elem c_τ_Root ⇒ (c_eco_τ, 1, :cEco)
    @rep_elem c_τ_Wood ⇒ (c_eco_τ, 2, :cEco)
    @rep_elem c_τ_Leaf ⇒ (c_eco_τ, 3, :cEco)
    @rep_elem c_τ_Reserve ⇒ (c_eco_τ, 4, :cEco)
    @rep_elem c_τ_LitFast ⇒ (c_eco_τ, 5, :cEco)
    @rep_elem c_τ_LitSlow ⇒ (c_eco_τ, 6, :cEco)
    @rep_elem c_τ_SoilSlow ⇒ (c_eco_τ, 7, :cEco)
    @rep_elem c_τ_SoilOld ⇒ (c_eco_τ, 8, :cEco)

    vegZix = getZix(land.pools.cVeg, helpers.pools.zix.cVeg)
    for ix ∈ eachindex(vegZix)
        @rep_elem p_C_to_N_cVeg[ix] ⇒ (C_to_N_cVeg, vegZix[ix], :cEco)
    end
    for i ∈ eachindex(c_eco_k_base)
        tmp = c_eco_τ[i]
        @rep_elem tmp ⇒ (c_eco_k_base, i, :cEco)
    end

    ## pack land variables
    @pack_nt begin
        (C_to_N_cVeg, c_eco_τ, c_eco_k_base, ηA, ηH) ⇒ land.diagnostics
        c_remain ⇒ land.states
    end
    return land
end

function adjustPackPoolComponents(land, helpers, ::cCycleBase_GSI)
    @unpack_nt (cVeg,
        cLit,
        cSoil,
        cVegRoot,
        cVegWood,
        cVegLeaf,
        cVegReserve,
        cLitFast,
        cLitSlow,
        cSoilSlow,
        cSoilOld,
        cEco) ⇐ land.pools

    zix = helpers.pools.zix
    for (lc, l) in enumerate(zix.cVeg)
        @rep_elem cEco[l] ⇒ (cVeg, lc, :cVeg)
    end

    for (lc, l) in enumerate(zix.cVegRoot)
        @rep_elem cEco[l] ⇒ (cVegRoot, lc, :cVegRoot)
    end

    for (lc, l) in enumerate(zix.cVegWood)
        @rep_elem cEco[l] ⇒ (cVegWood, lc, :cVegWood)
    end

    for (lc, l) in enumerate(zix.cVegLeaf)
        @rep_elem cEco[l] ⇒ (cVegLeaf, lc, :cVegLeaf)
    end

    for (lc, l) in enumerate(zix.cVegReserve)
        @rep_elem cEco[l] ⇒ (cVegReserve, lc, :cVegReserve)
    end

    for (lc, l) in enumerate(zix.cLit)
        @rep_elem cEco[l] ⇒ (cLit, lc, :cLit)
    end

    for (lc, l) in enumerate(zix.cLitFast)
        @rep_elem cEco[l] ⇒ (cLitFast, lc, :cLitFast)
    end

    for (lc, l) in enumerate(zix.cLitSlow)
        @rep_elem cEco[l] ⇒ (cLitSlow, lc, :cLitSlow)
    end

    for (lc, l) in enumerate(zix.cSoil)
        @rep_elem cEco[l] ⇒ (cSoil, lc, :cSoil)
    end

    for (lc, l) in enumerate(zix.cSoilSlow)
        @rep_elem cEco[l] ⇒ (cSoilSlow, lc, :cSoilSlow)
    end

    for (lc, l) in enumerate(zix.cSoilOld)
        @rep_elem cEco[l] ⇒ (cSoilOld, lc, :cSoilOld)
    end
    @pack_nt (cVeg,
        cLit,
        cSoil,
        cVegRoot,
        cVegWood,
        cVegLeaf,
        cVegReserve,
        cLitFast,
        cLitSlow,
        cSoilSlow,
        cSoilOld,
        cEco) ⇒ land.pools
    return land
end

purpose(::Type{cCycleBase_GSI}) = "Structure and properties of the carbon cycle components as needed for a dynamic phenology-based carbon cycle in the GSI approach."

@doc """

$(getModelDocString(cCycleBase_GSI))

---

# Extended help

*References*
 - Potter; C. S.; J. T. Randerson; C. B. Field; P. A. Matson; P. M.  Vitousek; H. A. Mooney; & S. A. Klooster. 1993. Terrestrial ecosystem  production: A process model based on global satellite & surface data.  Global Biogeochemical Cycles. 7: 811-841.

*Versions*
 - 1.0 on 28.02.2020 [skoirala | @dr-ko]  

*Created by*
 - ncarvalhais
"""
cCycleBase_GSI
