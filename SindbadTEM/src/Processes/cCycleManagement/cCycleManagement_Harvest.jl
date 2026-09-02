export cCycleManagement_Harvest

#! format: off
struct cCycleManagement_Harvest <: cCycleManagement end
#! format: on

function define(params::cCycleManagement_Harvest, forcing, land, helpers)
    @unpack_nt begin
        (c_giver, c_taker) ⇐ land.constants
        (cVeg, cEco) ⇐ land.pools
        zix ⇐ helpers.pools
        (z_zero, o_one) ⇐ land.constants
    end
    zix_veg_all = Tuple(vcat(getZix(cVeg, helpers.pools.zix.cVeg)...))
    c_lose_to_zix_vec = Tuple{Int}[]
    is_crop_harvest_pool = one.(cEco)
    is_wood_harvest_pool = one.(cEco)
    for zixVeg ∈ zix_veg_all
        # define what is harvesed for export from the system
        if helpers.pools.components.cEco[zixVeg] == :cVegRoot
            @rep_elem z_zero ⇒ (is_crop_harvest_pool, zixVeg, :cEco)
        end
        if helpers.pools.components.cEco[zixVeg] ∈ (:cVegRoot, :cVegLeaf)
            @rep_elem z_zero ⇒ (is_wood_harvest_pool, zixVeg, :cEco)
        end

        # make reserve pool flow to slow litter pool/woody debris
        if helpers.pools.components.cEco[zixVeg] == :cVegReserve
            # c_lose_to_zix = helpers.pools.zix.cLitSlow
            # instead of just going in cLitSlow, which can be very specific to the WROASTED model structure
            c_lose_to_zix = something(
                (
                    hasproperty(helpers.pools.zix, p) ? getproperty(helpers.pools.zix, p) : 
                    nothing for p in (:cLitSlow, :cLitFast, :cLit, :cSoilSlow, :cSoilOld, :cSoil)
                )..., 
            nothing)
            isnothing(c_lose_to_zix) && 
                error(
                    "Not clear where to which litter/soil pool send dead cVegReserve: expected cLitSlow, cLitFast, cLit, cSoilSlow, cSoilOld or cSoil"
                )
        else
            c_lose_to_zix = c_taker[[(c_giver .== zixVeg)...]]
        end
        ndxNoVeg = Int[]
        for ndxl ∈ c_lose_to_zix
            if ndxl ∉ zix_veg_all
                push!(ndxNoVeg, ndxl)
            end
        end
        push!(c_lose_to_zix_vec, Tuple(ndxNoVeg))
    end
    c_lose_to_zix_vec = Tuple(c_lose_to_zix_vec)

    # initialize management outputs
    c_Crop_Harvest_Product = zero.(cEco)
    c_Crop_Harvest_Mortality = zero.(cEco)
    c_Wood_Harvest_Product = zero.(cEco)
    c_Wood_Harvest_Mortality = zero.(cEco)

    @pack_nt begin 
        (zix_veg_all, c_lose_to_zix_vec, is_crop_harvest_pool, is_wood_harvest_pool) ⇒ land.cCycleManagement
        (c_Crop_Harvest_Product, c_Crop_Harvest_Mortality) ⇒ land.diagnostics
        (c_Wood_Harvest_Product, c_Wood_Harvest_Mortality) ⇒ land.diagnostics
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
        (zix_veg_all, c_lose_to_zix_vec, is_crop_harvest_pool, is_wood_harvest_pool) ⇐ land.cCycleManagement 
        (c_giver, c_taker) ⇐ land.constants
        (z_zero, o_one) ⇐ land.constants
        c_model ⇐ land.models
    end

    # make sure...
    @assert z_zero <= is_crop_harvest_pool + is_wood_harvest_pool <= o_one

    # calculate the mortality and the product from crop and forestry harvest
    for izix in zix.cEco
        # set c_Crop_Harvest_Product, c_Crop_Harvest_Mortality, c_Wood_Harvest_Product, c_Wood_Harvest_Mortality to 0
        # @rep_elem z_zero ⇒ (c_Crop_Harvest_Product, izix, :cEco)
        # @rep_elem z_zero ⇒ (c_Crop_Harvest_Mortality, izix, :cEco)
        # @rep_elem z_zero ⇒ (c_Wood_Harvest_Product, izix, :cEco)
        # @rep_elem z_zero ⇒ (c_Wood_Harvest_Mortality, izix, :cEco)
        
        # the actual harvest fraction cannot leave less than c_remain in cEco[izix]
        max_to_harvest_intensity = 1 - (c_remain / cEco[izix])
        actual_crop_harvest_intensity = min(frac_crop_harvest_intensity, max_to_harvest_intensity) * is_crop_harvested
        actual_wood_harvest_intensity = min(frac_wood_harvest_intensity, max_to_harvest_intensity) * is_wood_harvested
    
        @rep_elem cEco[izix] * actual_crop_harvest_intensity ⇒ (c_Crop_Harvest_Mortality, izix, :cEco)
        @rep_elem cEco[izix] * actual_crop_harvest_intensity * frac_crop_harvest_efficiency * is_crop_harvest_pool[izix] ⇒ (c_Crop_Harvest_Product, izix, :cEco)
        @rep_elem cEco[izix] * actual_wood_harvest_intensity ⇒ (c_Wood_Harvest_Mortality, izix, :cEco)
        @rep_elem cEco[izix] * actual_wood_harvest_intensity * frac_wood_harvest_efficiency * is_wood_harvest_pool[izix] ⇒ (c_Wood_Harvest_Product, izix, :cEco)
    end

    # compute harvest, and splits to litter
    for zixVeg ∈ zix_veg_all

        cExport = c_Crop_Harvest_Product[zixVeg] + c_Wood_Harvest_Product[zixVeg]
        cMortality = c_Crop_Harvest_Mortality[zixVeg] + c_Wood_Harvest_Mortality[zixVeg]

        # make sure...
        @assert z_zero <= cExport + cMortality <= cEco[zixVeg]
        cLoss = at_least_zero(cMortality - cExport) # should not be needed...

        # deplet the cVeg carbon that goes to the litter / soil pools
        @add_to_elem -cLoss ⇒ (cEco, zixVeg, :cEco)

        # transfer non exported part
        c_lose_to_zix = c_lose_to_zix_vec[zixVeg]
        for tZ ∈ eachindex(c_lose_to_zix)
            tarZix = c_lose_to_zix[tZ]
            toGain = cLoss / oftype(cLoss, length(c_lose_to_zix))
            @add_to_elem toGain ⇒ (cEco, tarZix, :cEco)
        end

        # deplet the cVeg carbon that goes to the export pools
        @add_to_elem -cExport ⇒ (cEco, zixVeg, :cEco)
        
        # export to crop products
        c_lose_to_zix = helpers.pools.zix.cProductsCrop
        for tZ ∈ eachindex(c_lose_to_zix)
            tarZix = c_lose_to_zix[tZ]
            toGain = c_Crop_Harvest_Product[zixVeg] / oftype(c_Crop_Harvest_Product[zixVeg], length(c_lose_to_zix))
            @add_to_elem toGain ⇒ (cEco, tarZix, :cEco)
        end
        
        # export to wood products
        c_lose_to_zix = helpers.pools.zix.cProductsWood
        for tZ ∈ eachindex(c_lose_to_zix)
            tarZix = c_lose_to_zix[tZ]
            toGain = c_Wood_Harvest_Product[zixVeg] / oftype(c_Wood_Harvest_Product[zixVeg], length(c_lose_to_zix))
            @add_to_elem toGain ⇒ (cEco, tarZix, :cEco)
        end
    end

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
