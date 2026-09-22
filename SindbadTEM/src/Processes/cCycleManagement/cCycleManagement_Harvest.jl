export cCycleManagement_Harvest

#! format: off
struct cCycleManagement_Harvest <: cCycleManagement end
#! format: on

function define(params::cCycleManagement_Harvest, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools
    @unpack_nt c_taker ⇐ land.cCycleBase

    # initialize management outputs
    c_Crop_Harvest_Product = zero(cEco)
    c_Crop_Harvest_Mortality = zero(cEco)
    c_Wood_Harvest_Product = zero(cEco)
    c_Wood_Harvest_Mortality = zero(cEco)
    c_Harvest_Flow = zero(cEco)
    

    @pack_nt begin 
        (c_Crop_Harvest_Product, c_Crop_Harvest_Mortality) ⇒ land.diagnostics
        (c_Wood_Harvest_Product, c_Wood_Harvest_Mortality) ⇒ land.diagnostics
        c_Harvest_Flow ⇒ land.diagnostics
    end
    return land
end

function compute(params::cCycleManagement_Harvest, forcing, land, helpers)
    ## unpack disturbance variables
    @unpack_nt begin
        (c_Crop_Harvest_Product, c_Crop_Harvest_Mortality, frac_crop_harvest_intensity, frac_crop_harvest_efficiency, is_crop_harvested) ⇐ land.diagnostics
        (c_Wood_Harvest_Product, c_Wood_Harvest_Mortality, frac_wood_harvest_intensity, frac_wood_harvest_efficiency, is_wood_harvested) ⇐ land.diagnostics
        cEco ⇐ land.pools
        zix ⇐ helpers.pools
        c_remain ⇐ land.states
        (c_giver, c_taker) ⇐ land.cCycleBase
        (z_zero, o_one) ⇐ land.constants
        c_model ⇐ land.models
        c_Harvest_Flow ⇐ land.diagnostics
    end

    # make sure...
    @assert z_zero <= is_crop_harvest_pool + is_wood_harvest_pool <= o_one

    @rep_vec c_Crop_Harvest_Product ⇒ helpers.pools.zeros.cEco
    @rep_vec c_Wood_Harvest_Product ⇒ helpers.pools.zeros.cEco

    # calculate the mortality and the product from crop and forestry harvest
    for fO ∈ c_flow_order
        giver = c_giver[fO]
        giver ∈ zix.cVeg || continue
        
        # the actual harvest fraction cannot leave less than c_remain in cEco[izix]
        max_to_harvest_intensity = 1 - (c_remain / cEco[giver])
        actual_crop_harvest_intensity = min(frac_crop_harvest_intensity, max_to_harvest_intensity) * is_crop_harvested
        actual_wood_harvest_intensity = min(frac_wood_harvest_intensity, max_to_harvest_intensity) * is_wood_harvested

        c_h_m = cEco[giver] * actual_crop_harvest_intensity
        c_h_p = cEco[giver] * actual_crop_harvest_intensity * frac_crop_harvest_efficiency * is_crop_harvest_pool[giver]
        w_h_m = cEco[giver] * actual_wood_harvest_intensity
        w_h_p = cEco[giver] * actual_wood_harvest_intensity * frac_wood_harvest_efficiency * is_wood_harvest_pool[giver]
        cExport = c_h_p + w_h_p
        cMortality = c_h_m + w_h_m
        @assert z_zero <= cExport + cMortality <= cEco[zixVeg]
        c_harvest_flow = at_least_zero(cMortality - cExport) * c_flow_QP_vec[fO] 

        @add_to_elem c_h_m ⇒ (c_Crop_Harvest_Mortality, giver)
        @add_to_elem c_h_p ⇒ (c_Crop_Harvest_Product, giver)
        @add_to_elem w_h_m ⇒ (c_Wood_Harvest_Mortality, giver)
        @add_to_elem w_h_p ⇒ (c_Wood_Harvest_Product, giver)
        @rep_elem c_harvest_flow ⇒ (c_Harvest_Flow, taker)
    end

    @rep_elem totalS(c_Crop_Harvest_Product) ⇒ (cEco, zix.cProductsCrop)
    @rep_elem totalS(c_Wood_Harvest_Product) ⇒ (cEco, zix.cProductsWood)


        # for zixVeg ∈ zix_veg_all

    #     cExport = c_Crop_Harvest_Product[zixVeg] + c_Wood_Harvest_Product[zixVeg]
    #     cMortality = c_Crop_Harvest_Mortality[zixVeg] + c_Wood_Harvest_Mortality[zixVeg]

    #     # make sure...
    #     @assert z_zero <= cExport + cMortality <= cEco[zixVeg]
    #     cLoss = at_least_zero(cMortality - cExport) # should not be needed...

    #     # deplet the cVeg carbon that goes to the litter / soil pools
    #     @add_to_elem -cLoss ⇒ (cEco, zixVeg)

    #     # transfer non exported part
    #     c_lose_to_zix = c_lose_to_zix_vec[zixVeg]
    #     for tZ ∈ eachindex(c_lose_to_zix)
    #         tarZix = c_lose_to_zix[tZ]
    #         toGain = cLoss / oftype(cLoss, length(c_lose_to_zix))
    #         @add_to_elem toGain ⇒ (cEco, tarZix)
    #     end

    #     # deplet the cVeg carbon that goes to the export pools
    #     @add_to_elem -cExport ⇒ (cEco, zixVeg)
        
    #     # export to crop products
    #     c_lose_to_zix = helpers.pools.zix.cProductsCrop
    #     for tZ ∈ eachindex(c_lose_to_zix)
    #         tarZix = c_lose_to_zix[tZ]
    #         toGain = c_Crop_Harvest_Product[zixVeg] / oftype(c_Crop_Harvest_Product[zixVeg], length(c_lose_to_zix))
    #         @add_to_elem toGain ⇒ (cEco, tarZix)
    #     end
        
    #     # export to wood products
    #     c_lose_to_zix = helpers.pools.zix.cProductsWood
    #     for tZ ∈ eachindex(c_lose_to_zix)
    #         tarZix = c_lose_to_zix[tZ]
    #         toGain = c_Wood_Harvest_Product[zixVeg] / oftype(c_Wood_Harvest_Product[zixVeg], length(c_lose_to_zix))
    #         @add_to_elem toGain ⇒ (cEco, tarZix)
    #     end
    # end

    # # compute harvest, and splits to litter
    # for zixVeg ∈ zix_veg_all

    #     cExport = c_Crop_Harvest_Product[zixVeg] + c_Wood_Harvest_Product[zixVeg]
    #     cMortality = c_Crop_Harvest_Mortality[zixVeg] + c_Wood_Harvest_Mortality[zixVeg]

    #     # make sure...
    #     @assert z_zero <= cExport + cMortality <= cEco[zixVeg]
    #     cLoss = at_least_zero(cMortality - cExport) # should not be needed...

    #     # deplet the cVeg carbon that goes to the litter / soil pools
    #     @add_to_elem -cLoss ⇒ (cEco, zixVeg)

    #     # transfer non exported part
    #     c_lose_to_zix = c_lose_to_zix_vec[zixVeg]
    #     for tZ ∈ eachindex(c_lose_to_zix)
    #         tarZix = c_lose_to_zix[tZ]
    #         toGain = cLoss / oftype(cLoss, length(c_lose_to_zix))
    #         @add_to_elem toGain ⇒ (cEco, tarZix)
    #     end

    #     # deplet the cVeg carbon that goes to the export pools
    #     @add_to_elem -cExport ⇒ (cEco, zixVeg)
        
    #     # export to crop products
    #     c_lose_to_zix = helpers.pools.zix.cProductsCrop
    #     for tZ ∈ eachindex(c_lose_to_zix)
    #         tarZix = c_lose_to_zix[tZ]
    #         toGain = c_Crop_Harvest_Product[zixVeg] / oftype(c_Crop_Harvest_Product[zixVeg], length(c_lose_to_zix))
    #         @add_to_elem toGain ⇒ (cEco, tarZix)
    #     end
        
    #     # export to wood products
    #     c_lose_to_zix = helpers.pools.zix.cProductsWood
    #     for tZ ∈ eachindex(c_lose_to_zix)
    #         tarZix = c_lose_to_zix[tZ]
    #         toGain = c_Wood_Harvest_Product[zixVeg] / oftype(c_Wood_Harvest_Product[zixVeg], length(c_lose_to_zix))
    #         @add_to_elem toGain ⇒ (cEco, tarZix)
    #     end
    # end

    ## pack land variables
    @pack_nt begin 
        cEco ⇒ land.pools
        (c_Crop_Harvest_Product, c_Wood_Harvest_Product, c_Crop_Harvest_Mortality, c_Wood_Harvest_Mortality) ⇒ land.diagnostics
        (actual_crop_harvest_intensity, actual_wood_harvest_intensity) ⇒ land.diagnostics
    end
    land = adjustPackPoolComponents(land, helpers, c_model)
    return land
end

purpose(::Type{cCycleManagement_Harvest}) = "This is used for crop and forestry harvest events. Moves carbon to export and decomposable pools, according to their respective carbon flow target pools, during harvest events."

@doc """

$(getModelDocString(cCycleManagement_Harvest))

---

# Extended help

*Created by*
    - Nuno | nunocarvalhais
"""
cCycleManagement_Harvest
