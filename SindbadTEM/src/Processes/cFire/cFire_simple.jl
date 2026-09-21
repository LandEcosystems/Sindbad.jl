export cFire

#! format: off
struct cFire_simple <: cFire end
#! format: on

function define(params::cFire_simple, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools

    # initialize disturbance outputs
    c_fire_mortality = zero(cEco)
    c_fire_efflux = zero(cEco)
    c_fire_flow = zero(cEco)
    @pack_nt begin 
        (c_fire_mortality, c_fire_efflux, c_fire_flow) ⇒ land.diagnostics
    end
    return land
end

function compute(params::cFire_simple, forcing, land, helpers)
    ## unpack disturbance variables
    @unpack_nt begin
        # for vegetation die-off
        c_f_cVeg_dieOff ⇐ land.diagnostics
        # for fires
        (c_fire_mortality, c_fire_efflux, c_fire_flow, c_fire_fba, c_flow_QP_vec) ⇐ land.diagnostics
        # for fires
        (c_Fire_cci, c_Fire_k) ⇐ land.diagnostics
        cEco ⇐ land.pools
        c_remain ⇐ land.states
        (c_giver, c_taker, zix_cHeterotrophic) ⇐ land.cCycleBase
        c_model ⇐ land.models
    end
    # set c_fire_efflux and c_fire_mortality and cFireTotal to 0
    cFireTotal = zero(eltype(cEco))
    @rep_vec c_fire_efflux ⇒ helpers.pools.zeros.cEco
    @rep_vec c_fire_mortality ⇒ helpers.pools.zeros.cEco
    @rep_vec c_fire_flow ⇒ helpers.pools.zeros.cEco
    zix_cVeg = helpers.pools.zix.cVeg

    # if there is not fire and no dieoff, pack and return
    if c_fire_fba != zero(c_fire_fba) || c_f_cVeg_dieOff != zero(c_f_cVeg_dieOff)
        for fO ∈ c_flow_order
            c_giver[fO] ∈ zix_cVeg || continue
            # total mortality fraction of vegetation pool
            f_loss = c_f_cVeg_dieOff + c_fire_fba * c_Fire_k[zixVeg]
            cLoss = (at_least_zero(cEco[zixVeg] - c_remain) * f_loss) * c_flow_QP_vec[fO]
            # part that is combusted and that goes to the litter pools
            cLossFire = safe_divide(cLoss * (c_fire_fba * c_Fire_k[zixVeg]), f_loss * c_Fire_cci[zixVeg])
            cLossNonFire = cLoss - cLossFire

            @add_to_elem cLossFire ⇒ (c_fire_efflux, c_giver[fO])
            @add_to_elem cLossNonFire ⇒ (c_fire_flow, taker[fO])
            @add_to_elem cLoss ⇒ (c_fire_mortality, c_giver[fO])

            #=
            # deplete pool
            @add_to_elem -cLoss ⇒ (cEco, c_giver[fO])
            # transfer non combusted part
            @add_to_elem cLossNonFire ⇒ (cEco, c_taker[fO])
            # feed c_fire_efflux and c_fire_mortality (@rep_elem)
            @add_to_elem cLossFire ⇒ (c_fire_efflux, c_giver[fO])
            @add_to_elem cLoss ⇒ (c_fire_mortality, c_giver[fO])
            =#
        end

        # compute fire flux from litter and soils
        for zix ∈ zix_cHeterotrophic
            # total combustion from pool
            f_loss = c_fire_fba * c_Fire_cci[zix]
            cLoss = at_least_zero(cEco[zix] * f_loss)
            #=
            # deplete pool
            @add_to_elem -cLoss ⇒ (cEco, zix) 
            =#
            @rep_elem cLoss ⇒ (c_fire_efflux, zix)
        end
        # total fire flux
        cFireTotal = totalS(c_fire_efflux)
    end

    ## pack land variables
    @pack_nt begin 
        # cEco ⇒ land.pools
        cFireTotal ⇒ land.fluxes
        (c_fire_mortality, c_fire_efflux, c_fire_flow) ⇒ land.diagnostics
    end
    # land = adjustPackPoolComponents(land, helpers, c_model)
    return land
end

purpose(::Type{cFire_simple}) = "This is used for vegetation die-off and fire disturbance events. Moves carbon in reserve pool to slow litter pool, and all other carbon pools except reserve pool to their respective carbon flow target pools during disturbance events."

@doc """

$(getModelDocString(cFire_simple))

---

# Extended help

*Created by*
    - Nuno | nunocarvalhais
"""
cFire_simple
