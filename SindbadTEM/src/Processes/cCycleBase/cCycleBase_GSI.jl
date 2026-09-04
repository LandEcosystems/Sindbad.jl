export cCycleBase_GSI

#! format: off
@bounds @describe @units @timescale @with_kw struct cCycleBase_GSI{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12} <: cCycleBase
    c_τ_Root::T1 = 1.0 | (0.05, 3.3) | "turnover rate of root carbon pool" | "year-1" | "year"
    c_τ_Wood::T2 = 0.03 | (0.001, 10.0) | "turnover rate of wood carbon pool" | "year-1" | "year"
    c_τ_Leaf::T3 = 1.0 | (0.05, 10.0) | "turnover rate of leaf carbon pool" | "year-1" | "year"
    c_τ_Reserve::T4 = 1.0e-11 | (1.0e-12, 1.0) | "Reserve does not respire, but has a small value to avoid  numerical error" | "year-1" | "year"
    c_τ_LitFast::T5 = 14.8 | (0.5, 148.0) | "turnover rate of fast litter (leaf litter) carbon pool" | "year-1" | "year"
    c_τ_LitSlow::T6 = 3.9 | (0.39, 39.0) | "turnover rate of slow litter carbon (wood litter) pool" | "year-1" | "year"
    c_τ_SoilSlow::T7 = 0.2 | (0.02, 2.0) | "turnover rate of slow soil carbon pool" | "year-1" | "year"
    c_τ_SoilOld::T8 = 0.0045 | (0.00045, 0.045) | "turnover rate of old soil carbon pool" | "year-1" | "year"
    p_C_to_N_cVeg::T9 = Float64.([25.0, 260.0, 260.0, 10.0]) | (-Inf, Inf) | "carbon to nitrogen ratio in vegetation pools" | "gC/gN" | ""
    ηH::T10 = 1.0 | (0.01, 100.0) | "scaling factor for heterotrophic pools after spinup" | "" | ""
    ηA::T11 = 1.0 | (0.01, 100.0) | "scaling factor for vegetation pools after spinup" | "" | ""
    c_remain::T12 = 10.0 | (0.1, 100.0) | "remaining carbon after disturbance" | "" | ""
end
#! format: on

function define(params::cCycleBase_GSI, forcing, land, helpers)
    @unpack_cCycleBase_GSI params
    @unpack_nt cEco ⇐ land.pools
    ## Instantiate variables
    C_to_N_cVeg = zero(cEco) #sujan
    # C_to_N_cVeg[helpers.pools.zix.cVeg] .= p_C_to_N_cVeg
    c_eco_k_base = zero(cEco)
    c_eco_τ = zero(cEco)

    # one flow per declared edge of this approach, resolved against the configured
    # pool structure, rather than a transfer matrix carried as a parameter. The same
    # call keys the flows by pool-name pair, so a cFlow approach reads the topology
    # instead of rederiving it
    (c_flow_order, c_taker, c_giver, c_flow_named_edges) = cFlowStructure(params, cEco, helpers)

    c_model = cCycleBase_GSI()

    ## pack land variables
    @pack_nt begin
        (c_flow_order, c_taker, c_giver) ⇒ land.constants
        c_flow_named_edges ⇒ land.cCycleBase
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
    # c_eco_τ is written by pool name rather than by cEco position, so a structure
    # that orders or omits pools differently still gets its turnovers in the right
    # slots
    for ix ∈ helpers.pools.zix.cVegRoot
        @rep_elem c_τ_Root ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cVegWood
        @rep_elem c_τ_Wood ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cVegLeaf
        @rep_elem c_τ_Leaf ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cVegReserve
        @rep_elem c_τ_Reserve ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cLitFast
        @rep_elem c_τ_LitFast ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cLitSlow
        @rep_elem c_τ_LitSlow ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cSoilSlow
        @rep_elem c_τ_SoilSlow ⇒ (c_eco_τ, ix, :cEco)
    end
    for ix ∈ helpers.pools.zix.cSoilOld
        @rep_elem c_τ_SoilOld ⇒ (c_eco_τ, ix, :cEco)
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

poolConfiguration(::Type{<:cCycleBase_GSI}) = CarbonPoolsGSI
cFlowEdges(::Type{<:cCycleBase_GSI}) = GSI_FLOW_EDGES
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
