export cForestryHarvest_simple

#! format: off
struct cForestryHarvest_simple <: cForestryHarvest end
#! format: on

function define(params::cForestryHarvest_simple, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools
    @unpack_nt c_taker ⇐ land.cCycleBase

    # initialize management outputs
    c_Wood_Harvest_Product = zero(cEco)
    c_Wood_Harvest_Mortality = zero(cEco)
    c_Wood_Harvest_Flow = zero(cEco)

    @pack_nt begin 
        (c_Wood_Harvest_Product, c_Wood_Harvest_Mortality, c_Wood_Harvest_Flow) ⇒ land.diagnostics
    end
    return land
end

function compute(params::cForestryHarvest_simple, forcing, land, helpers)
    ## unpack disturbance variables
    @unpack_nt begin
        (c_Wood_Harvest_Product, c_Wood_Harvest_Mortality, frac_wood_harvest_intensity, frac_wood_harvest_efficiency, is_wood_harvested) ⇐ land.diagnostics
        cEco ⇐ land.pools
        zix ⇐ helpers.pools
        c_remain ⇐ land.states
        (c_giver, c_taker) ⇐ land.cCycleBase
        (z_zero, o_one) ⇐ land.constants
        c_model ⇐ land.models
        (c_Wood_Harvest_Flow) ⇐ land.diagnostics
    end

    # make sure...
    @assert z_zero <= is_wood_harvested <= o_one

    @rep_vec c_Wood_Harvest_Product ⇒ helpers.pools.zeros.cEco
    @rep_vec c_Wood_Mortality_Product ⇒ helpers.pools.zeros.cEco
    @rep_vec c_Wood_Harvest_Flow ⇒ helpers.pools.zeros.cEco

    cWoodProducts = z_zero

    # calculate the mortality and the product from crop and forestry harvest
    if is_wood_harvested != z_zero
        for fO ∈ c_flow_order
            giver = c_giver[fO]
            giver ∈ zix.cVeg || continue
            taker = c_taker[fO]
            
            # the actual harvest fraction cannot leave less than c_remain in cEco[izix]
            max_to_harvest_intensity = 1 - safe_divide(c_remain, cEco[giver])
            actual_wood_harvest_intensity = min(frac_wood_harvest_intensity, max_to_harvest_intensity) * is_wood_harvested * c_flow_QP_vec[fO] 

            w_h_m = cEco[giver] * actual_wood_harvest_intensity
            w_h_p = cEco[giver] * actual_wood_harvest_intensity * frac_wood_harvest_efficiency * is_wood_harvest_pool[giver]
            w_h_f = at_least_zero(w_h_m - w_h_p)

            @add_to_elem w_h_m ⇒ (c_Wood_Harvest_Mortality, giver)
            @add_to_elem w_h_p ⇒ (c_Wood_Harvest_Product, giver)
            @add_to_elem w_h_f ⇒ (c_Wood_Harvest_Flow, taker)
        end

        cWoodProducts = totalS(c_Crop_Harvest_Product)  
    end

    land = adjustPackPoolComponents(land, helpers, c_model)

    ## pack land variables
    @pack_nt begin 
        (c_Wood_Harvest_Product, c_Wood_Harvest_Mortality, c_Wood_Harvest_Flow) ⇒ land.diagnostics
        (actual_wood_harvest_intensity, cWoodProducts) ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cForestryHarvest_simple}) = "This is used for crop and forestry harvest events. Moves carbon to export and decomposable pools, according to their respective carbon flow target pools, during harvest events."

@doc """

$(getModelDocString(cForestryHarvest_simple))

---

# Extended help

*Created by*
    - Nuno | nunocarvalhais
"""
cForestryHarvest_simple
