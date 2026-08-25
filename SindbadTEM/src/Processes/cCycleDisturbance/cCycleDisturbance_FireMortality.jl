export cCycleDisturbance_WROASTEDMortality

#! format: off
struct cCycleDisturbance_WROASTEDMortality <: cCycleDisturbance end
#! format: on

function define(params::cCycleDisturbance_WROASTEDMortality, forcing, land, helpers)
    @unpack_nt begin
        (c_giver, c_taker) ⇐ land.constants
        (cVeg, cEco) ⇐ land.pools
        zix ⇐ helpers.pools
        (z_zero, o_one) ⇐ land.constants
    end
    zix_veg_all = Tuple(vcat(getZix(cVeg, helpers.pools.zix.cVeg)...))
    c_lose_to_zix_vec = Tuple{Int}[]
    for zixVeg ∈ zix_veg_all
        # make reserve pool flow to slow litter pool/woody debris
        if helpers.pools.components.cEco[zixVeg] == :cVegReserve
            c_lose_to_zix = helpers.pools.zix.cLitSlow
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

    # initialize disturbance outputs
    # c_Veg_Mortality = zero.(cVeg)
    c_Veg_Mortality = zero.(cEco)
    c_Fire_Flux = zero.(cEco)
    cFireTotal = z_zero

    @pack_nt begin 
        (zix_veg_all, c_lose_to_zix_vec) ⇒ land.cCycleDisturbance
        (c_Veg_Mortality, c_Fire_Flux) ⇒ land.diagnostics
        cFireTotal ⇒ land.fluxes
    end
    return land
end

function compute(params::cCycleDisturbance_WROASTEDMortality, forcing, land, helpers)
    ## unpack disturbance variables
    @unpack_nt begin
        # for vegetation die-off
        c_fVegDieOff ⇐ land.diagnostics
        # for fires
        (c_Veg_Mortality, c_Fire_Flux, c_fire_fba) ⇐ land.diagnostics
        # for fires
        (c_Fire_cci, c_Fire_k) ⇐ land.diagnostics
        cEco ⇐ land.pools
        cFireTotal ⇐ land.fluxes
        zix ⇐ helpers.pools
        c_remain ⇐ land.states
        (zix_veg_all, c_lose_to_zix_vec) ⇐ land.cCycleDisturbance # TODO: double check the new flow for fire, are indices correct?
        (c_giver, c_taker) ⇐ land.constants
        (z_zero, o_one) ⇐ land.constants
        c_model ⇐ land.models
    end
    # set c_Fire_Flux and c_Veg_Mortality and cFireTotal to 0
    cFireTotal = z_zero
    for izix in zix.cEco
        @rep_elem z_zero ⇒ (c_Fire_Flux, izix, :cEco)
        @rep_elem z_zero ⇒ (c_Veg_Mortality, izix, :cEco)
    end

    # if there is not fire and no dieoff, pack and return
    if c_fire_fba != 0.0f0 || c_fVegDieOff != 0.0f0
        # @show c_fire_fba, c_fVegDieOff
        # compute vegetation mortality, and splits to litter and atmosphere
        for zixVeg ∈ zix_veg_all
            # total mortality fraction of vegetation pool
            f_loss = c_fVegDieOff + c_fire_fba * c_Fire_k[zixVeg]
            cLoss = maxZero(cEco[zixVeg] - c_remain) * f_loss
            # part that is combusted and that goes to the litter pools
            cLossFire = cLoss * (c_fire_fba * c_Fire_k[zixVeg]) / f_loss * c_Fire_cci[zixVeg] # ? if f_loss is zero this is undefined
            cLossSoil = cLoss - cLossFire
            # deplet pool
            @add_to_elem -cLoss ⇒ (cEco, zixVeg, :cEco)
            # transfer non combusted part
            c_lose_to_zix = c_lose_to_zix_vec[zixVeg]
            for tZ ∈ eachindex(c_lose_to_zix)
                tarZix = c_lose_to_zix[tZ]
                toGain = cLossSoil / oftype(cLossSoil, length(c_lose_to_zix))
                @add_to_elem toGain ⇒ (cEco, tarZix, :cEco)
            end
            # feed c_Fire_Flux and c_Veg_Mortality (@rep_elem)
            @rep_elem cLossFire ⇒ (c_Fire_Flux, zixVeg, :cEco)
            @rep_elem cLoss ⇒ (c_Veg_Mortality, zixVeg, :cEco)
        end

        # compute fire flux from litter and soils
        for zixDead ∈ (zix.cLit..., zix.cSoil...)
            # total combustion from pool
            f_loss = c_fire_fba * c_Fire_cci[zixDead]
            cLoss = maxZero(cEco[zixDead] * f_loss)
            cLossFire = cLoss
            # deplet pool
            @add_to_elem -cLoss ⇒ (cEco, zixDead, :cEco) # ? this one is also a new addition
            # Print at every time step, left and right!
            # feed c_Fire_Flux
            @rep_elem cLossFire ⇒ (c_Fire_Flux, zixDead, :cEco)
        end
        # total fire flux
        cFireTotal = totalS(c_Fire_Flux)
    end

    ## pack land variables
    @pack_nt begin 
        cEco ⇒ land.pools
        cFireTotal ⇒ land.fluxes
        (c_Veg_Mortality, c_Fire_Flux) ⇒ land.diagnostics
    end
    land = adjustPackPoolComponents(land, helpers, c_model)
    return land
end

purpose(::Type{cCycleDisturbance_WROASTEDMortality}) = "This is used for vegetation die-off and fire disturbance events. Moves carbon in reserve pool to slow litter pool, and all other carbon pools except reserve pool to their respective carbon flow target pools during disturbance events."

@doc """

$(getModelDocString(cCycleDisturbance_WROASTEDMortality))

---

# Extended help

*Created by*
    - Nuno | nunocarvalhais
"""
cCycleDisturbance_WROASTEDMortality
