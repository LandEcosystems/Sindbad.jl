export cCropHarvest_simple

#! format: off
struct cCropHarvest_simple <: cCropHarvest_simple end
#! format: on

function define(params::cCropHarvest_simple, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools
    @unpack_nt c_taker ⇐ land.cCycleBase

    # initialize management outputs
    c_Crop_Harvest_Product = zero(cEco)
    c_Crop_Harvest_Mortality = zero(cEco)
    c_Crop_Harvest_Flow = zero(cEco)

    @pack_nt begin 
        (c_Crop_Harvest_Product, c_Crop_Harvest_Mortality, c_Crop_Harvest_Flow) ⇒ land.diagnostics
    end
    return land
end

function compute(params::cCropHarvest_simple, forcing, land, helpers)
    ## unpack disturbance variables
    @unpack_nt begin
        (c_Crop_Harvest_Product, c_Crop_Harvest_Mortality, frac_crop_harvest_intensity, frac_crop_harvest_efficiency, is_crop_harvested) ⇐ land.diagnostics
        cEco ⇐ land.pools
        zix ⇐ helpers.pools
        c_remain ⇐ land.states
        (c_giver, c_taker) ⇐ land.cCycleBase
        (z_zero, o_one) ⇐ land.constants
        c_model ⇐ land.models
        (c_Crop_Harvest_Flow) ⇐ land.diagnostics
    end

    # make sure...
    @assert z_zero <= is_crop_harvested <= o_one

    @rep_vec c_Crop_Harvest_Product ⇒ helpers.pools.zeros.cEco
    @rep_vec c_Crop_Mortality_Product ⇒ helpers.pools.zeros.cEco
    @rep_vec c_Crop_Harvest_Flow ⇒ helpers.pools.zeros.cEco

    cCropProducts = z_zero

    # calculate the mortality and the product from crop and Crop harvest
    if is_crop_harvested != z_zero
        for fO ∈ c_flow_order
            giver = c_giver[fO]
            giver ∈ zix.cVeg || continue
            taker = c_taker[fO]
            
            # the actual harvest fraction cannot leave less than c_remain in cEco[izix]
            max_to_harvest_intensity = 1 - safe_divide(c_remain, cEco[giver])
            actual_crop_harvest_intensity = min(frac_crop_harvest_intensity, max_to_harvest_intensity) * is_crop_harvested * c_flow_QP_vec[fO] 

            c_h_m = cEco[giver] * actual_crop_harvest_intensity
            c_h_p = cEco[giver] * actual_crop_harvest_intensity * frac_crop_harvest_efficiency * is_crop_harvest_pool[giver]
            c_h_f = at_least_zero(c_h_m - c_h_p)

            @add_to_elem c_h_m ⇒ (c_Crop_Harvest_Mortality, giver)
            @add_to_elem c_h_p ⇒ (c_Crop_Harvest_Product, giver)
            @add_to_elem c_h_f ⇒ (c_Crop_Harvest_Flow, taker)
        end

        cCropProducts = totalS(c_Crop_Harvest_Product)  
    end

    land = adjustPackPoolComponents(land, helpers, c_model)

    ## pack land variables
    @pack_nt begin 
        (c_Crop_Harvest_Product, c_Crop_Harvest_Mortality, c_Crop_Harvest_Flow) ⇒ land.diagnostics
        (actual_crop_harvest_intensity, cCropProducts) ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cCropHarvest_simple}) = "This is used for crop and Crop harvest events. Moves carbon to export and decomposable pools, according to their respective carbon flow target pools, during harvest events."

@doc """

$(getModelDocString(cCropHarvest_simple))

---

# Extended help

*Created by*
    - Nuno | nunocarvalhais
"""
cCropHarvest_simple
