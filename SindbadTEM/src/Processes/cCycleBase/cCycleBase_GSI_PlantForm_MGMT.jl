export cCycleBase_GSI_PlantForm_MGMT

#! format: off
@bounds @describe @units @timescale @with_kw struct cCycleBase_GSI_PlantForm_MGMT{
    T1,  # c_τ_Root_scalar
    T2,  # c_τ_Wood_scalar
    T3,  # c_τ_Leaf_scalar
    T4,  # c_τ_Litter_scalar
    T5,  # c_τ_Reserve_scalar
    T6,  # c_τ_Soil_scalar
    T7,  # c_τ_tree
    T8,  # c_τ_shrub
    T9,  # c_τ_herb
    T10, # c_τ_LitFast
    T11, # c_τ_LitSlow
    T12, # c_τ_SoilSlow
    T13, # c_τ_SoilOld
    T14, # c_τ_cProductsWood
    T15, # c_τ_cProductsCrop
    T16, # p_C_to_N_cVeg
    T17, # ηH
    T18, # ηA
    T19  # c_remain
} <: cCycleBase
    c_τ_Root_scalar::T1 = 1.0 | (0.25, 4) | "scalar for turnover rate of root carbon pool" | "-" | ""
    c_τ_Wood_scalar::T2 = 1.0 | (0.25, 4) | "scalar for turnover rate of wood carbon pool" | "-" | ""
    c_τ_Leaf_scalar::T3 = 1.0 | (0.25, 4) | "scalar for turnover rate of leaf carbon pool" | "-" | ""
    c_τ_Litter_scalar::T4 = 1.0 | (0.25, 4) | "scalar for turnover rate of litter carbon pool" | "-" | ""
    c_τ_Reserve_scalar::T5 = 1.0 | (0.25, 4) | "scalar for Reserve does not respire, but has a small value to avoid numerical error" | "-" | ""
    c_τ_Soil_scalar::T6 = 1.0 | (0.25, 4) | "scalar for turnover rate of soil carbon pool" | "-" | ""

#    c_τ_tree::T7 = Float64.(1.0 ./ [1.0, 50.0, 1.0, 50]) | (1 ./[4.0, 200.0, 4.0, 200.0], 1 ./[0.25, 12.5, 0.25, 12.5]) | "turnover of different organs of trees" | "year-1" | "year"
#    c_τ_shrub::T8 = Float64.(1.0 ./ [1.0, 5.0, 1.0, 2]) | (1 ./[4.0, 20.0, 4.0, 20], 1 ./[0.25, 1.25, 0.25, 1.25]) | "turnover of different organs of shrubs" | "year-1" | "year"
#    c_τ_herb::T9 = Float64.(1.0 ./ [0.75, 0.75, 0.75, 1.5]) | (1 ./[3.0, 3.0, 3.0, 6], 1 ./[0.1875, 0.1875, 0.1875, 0.375]) | "turnover of different organs of herbs" | "year-1" | "year"

    c_τ_tree::T7 = Float64.(1.0 ./ [1.0, 50.0, 1.0, 1.0e11]) | (1 ./[4.0, 200.0, 4.0, 4.0e11], 1 ./[0.25, 12.5, 0.25, 0.25e11]) | "turnover of different organs of trees" | "year-1" | "year"
    c_τ_shrub::T8 = Float64.(1.0 ./ [1.0, 5.0, 1.0, 1.0e11]) | (1 ./[4.0, 20.0, 4.0, 4.0e11], 1 ./[0.25, 1.25, 0.25, 0.25e11]) | "turnover of different organs of shrubs" | "year-1" | "year"
    c_τ_herb::T9 = Float64.(1.0 ./ [0.75, 0.75, 0.75, 0.75e11]) | (1 ./[3.0, 3.0, 3.0, 3.0e11], 1 ./[0.1875, 0.1875, 0.1875, 0.1875e11]) | "turnover of different organs of herbs" | "year-1" | "year"

    c_τ_LitFast::T10 = 14.8 | (0.5, 148.0) | "turnover rate of fast litter (leaf litter) carbon pool" | "year-1" | "year"
    c_τ_LitSlow::T11 = 3.9 | (0.39, 39.0) | "turnover rate of slow litter carbon (wood litter) pool" | "year-1" | "year"
    c_τ_SoilSlow::T12 = 0.2 | (0.02, 2.0) | "turnover rate of slow soil carbon pool" | "year-1" | "year"
    c_τ_SoilOld::T13 = 0.0045 | (0.00045, 0.045) | "turnover rate of old soil carbon pool" | "year-1" | "year"

    c_τ_cProductsWood::T14 = 0.03 | (0.01, 0.05) | "turnover rate of harvested wood products" | "year-1" | "year"
    c_τ_cProductsCrop::T15 = 1 | (0.25, 4) | "turnover rate of harvested crop products" | "year-1" | "year"

    p_C_to_N_cVeg::T16 = Float64.([25.0, 260.0, 260.0, 10.0]) | (-Inf, Inf) | "carbon to nitrogen ratio in vegetation pools" | "gC/gN" | ""
    ηH::T17 = 1.0 | (0.125, 8.0) | "scaling factor for heterotrophic pools after spinup" | "" | ""
    ηA::T18 = 1.0 | (0.25, 4.0) | "scaling factor for vegetation pools after spinup" | "" | ""
    c_remain::T19 = 50.0 | (0.1, 100.0) | "remaining carbon after disturbance" | "gC/m2" | ""
end
#! format: on

function define(params::cCycleBase_GSI_PlantForm_MGMT, forcing, land, helpers)
    @unpack_cCycleBase_GSI_PlantForm_MGMT params
    @unpack_nt begin
        cEco ⇐ land.pools
        (z_zero, o_one) ⇐ land.constants
    end
    ## Instantiate variables
    C_to_N_cVeg = zero(cEco) #sujan
    # C_to_N_cVeg[helpers.pools.zix.cVeg] .= p_C_to_N_cVeg # not used...
    c_eco_k_base = zero(cEco)
    c_eco_τ = zero(cEco)

    # if there is flux order check that is consistent
    # the transfer matrix is generated from this approach's declared cFlowEdges, resolved
    # against the configured pool structure, rather than carried as a parameter
    c_flow_A_array = cFlowMatrix(params, cEco, helpers)

    c_flow_order = Tuple(collect(1:length(findall(>(z_zero), c_flow_A_array))))
    c_taker = Tuple([ind[1] for ind ∈ findall(>(z_zero), c_flow_A_array)])
    c_giver = Tuple([ind[2] for ind ∈ findall(>(z_zero), c_flow_A_array)])

    # resolved once here so cFlow approaches read the topology instead of rederiving it
    c_flow_named_edges = cFlowNamedEdges(c_taker, c_giver, helpers.pools.components.cEco)

    c_model = cCycleBase_GSI_PlantForm_MGMT()

    zero_c_τ_pf = zero(c_τ_tree)

    ## pack land variables
    @pack_nt begin
        c_flow_A_array ⇒ land.diagnostics
        (c_flow_order, c_taker, c_giver) ⇒ land.constants
        (C_to_N_cVeg, c_eco_τ, c_eco_k_base, zero_c_τ_pf) ⇒ land.diagnostics
        c_flow_named_edges ⇒ land.cCycleBase
        c_model ⇒ land.models
    end
    return land
end

function get_c_τ(τ_pf, ::cCycleBase_GSI_PlantForm_MGMT)
    τ_root = τ_pf[1]
    τ_wood = τ_pf[2]
    τ_leaf = τ_pf[3]
    τ_reserve = τ_pf[4]
    return τ_root, τ_wood, τ_leaf, τ_reserve 
end

function precompute(params::cCycleBase_GSI_PlantForm_MGMT, forcing, land, helpers)
    @unpack_cCycleBase_GSI_PlantForm_MGMT params
    @unpack_nt begin
        (C_to_N_cVeg, c_eco_k_base, c_eco_τ, zero_c_τ_pf) ⇐ land.diagnostics
        (z_zero, o_one) ⇐ land.constants
        plant_form ⇐ land.states
    end

    c_τ_pf = zero_c_τ_pf
    ## replace values
    if plant_form == :tree
        c_τ_pf = c_τ_tree
    elseif plant_form == :shrub
        c_τ_pf = c_τ_shrub
    elseif plant_form == :herb
        c_τ_pf = c_τ_herb
    end

    c_τ_Root, c_τ_Wood, c_τ_Leaf, c_τ_Reserve = get_c_τ(c_τ_pf, params)
    # c_eco_τ is written by pool name rather than by cEco position, so a structure that
    # orders or omits pools differently still gets its turnovers in the right slots
    for ix ∈ helpers.pools.zix.cVegRoot
        @rep_elem c_τ_Root * c_τ_Root_scalar ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cVegWood
        @rep_elem c_τ_Wood * c_τ_Wood_scalar ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cVegLeaf
        @rep_elem c_τ_Leaf * c_τ_Leaf_scalar ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cVegReserve
        @rep_elem c_τ_Reserve * c_τ_Reserve_scalar ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cLitFast
        @rep_elem c_τ_LitFast * c_τ_Litter_scalar ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cLitSlow
        @rep_elem c_τ_LitSlow * c_τ_Litter_scalar ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cSoilSlow
        @rep_elem c_τ_SoilSlow * c_τ_Soil_scalar ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cSoilOld
        @rep_elem c_τ_SoilOld * c_τ_Soil_scalar ⇒ (c_eco_τ, ix, :cEco)
    end

    vegZix = helpers.pools.zix.cVeg
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

poolConfiguration(::Type{<:cCycleBase_GSI_PlantForm_MGMT}) = CarbonPoolsMGMT
cFlowEdges(::Type{<:cCycleBase_GSI_PlantForm_MGMT}) = GSI_FLOW_EDGES
purpose(::Type{cCycleBase_GSI_PlantForm_MGMT}) = "Same as GSI, additionally allowing for scaling of turnover parameters based on plant forms."

@doc """

$(getModelDocString(cCycleBase_GSI_PlantForm_MGMT))

---

# Extended help

*References*
 - Potter; C. S.; J. T. Randerson; C. B. Field; P. A. Matson; P. M.  Vitousek; H. A. Mooney; & S. A. Klooster. 1993. Terrestrial ecosystem  production: A process model based on global satellite & surface data.  Global Biogeochemical Cycles. 7: 811-841.

*Versions*
 - 1.0 on 28.02.2020 [skoirala | @dr-ko]  

*Created by*
 - ncarvalhais
"""
cCycleBase_GSI_PlantForm_MGMT
