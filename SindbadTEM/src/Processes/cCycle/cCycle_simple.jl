export cCycle_simple

struct cCycle_simple <: cCycle end

function define(params::cCycle_simple, forcing, land, helpers)
    @unpack_nt begin
        (z_zero, o_one) ⇐ land.constants
        (cEco, cVeg) ⇐ land.pools
    end
    ## Instantiate variables
    c_eco_flow = zero(cEco)
    c_eco_out = zero(cEco)
    c_eco_efflux = zero(cEco)
    c_eco_influx = zero(cEco)
    zero_c_eco_flow = zero(c_eco_flow)
    zero_c_eco_influx = zero(c_eco_influx)
    c_eco_npp = zero(cEco)

    cEco_prev = copy(cEco)
    zixVeg = getZix(cVeg, helpers.pools.zix.cVeg)
    ## pack land variables
    nee = z_zero
    npp = z_zero
    auto_respiration = z_zero
    eco_respiration = z_zero
    hetero_respiration = z_zero

    @pack_nt begin
        zixVeg ⇒ land.cCycle
        (c_eco_efflux, c_eco_flow, c_eco_influx, c_eco_out, c_eco_npp, zero_c_eco_flow, zero_c_eco_influx) ⇒ land.fluxes
        cEco_prev ⇒ land.states
        (nee, npp, auto_respiration, eco_respiration, hetero_respiration) ⇒ land.fluxes
    end
    return land
end

function compute(params::cCycle_simple, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        zixVeg ⇐ land.cCycle
        (c_eco_efflux, c_eco_flow, c_eco_influx, c_eco_out, c_eco_npp, zero_c_eco_flow, zero_c_eco_influx) ⇐ land.fluxes
        cEco_prev ⇐ land.states
        (cEco, cVeg) ⇐ land.pools
        (c_flow_A_vec, c_eco_k, c_allocation) ⇐ land.diagnostics
        ΔcEco ⇐ land.pools
        gpp ⇐ land.fluxes
        (c_giver, c_taker) ⇐ land.cCycleBase
        (c_flow_order) ⇐ land.cCycleBase
        (z_zero, o_one) ⇐ land.constants
    end
    ## reset ecoflow and influx to be zero at every time step
    c_eco_flow = zero_c_eco_flow .* z_zero
    c_eco_influx = c_eco_influx
    ## compute losses
    c_eco_out = min.(cEco, cEco .* c_eco_k)

    ## gains to vegetation
    for zv ∈ zixVeg
        @rep_elem gpp * c_allocation[zv] - c_eco_efflux[zv] ⇒ (c_eco_npp, zv, :cEco)
        @rep_elem c_eco_npp[zv] ⇒ (c_eco_influx, zv, :cEco)
    end

    # flows & losses
    # @nc; if flux order does not matter; remove# sujanq: this was deleted by simon in the version of 2020-11. Need to
    # find out why. Led to having zeros in most of the carbon pools of the
    # explicit simple
    # old before cleanup was removed during biomascat when cFlowAct was changed to gsi. But original cFlowAct CASA was writing c_flow_order. So; in biomascat; the fields do not exist & this block of code will not work.
    for jix ∈ eachindex(c_flow_order)
        fO = c_flow_order[jix]
        take_r = c_taker[fO]
        give_r = c_giver[fO]
        # carbon coming into another pool
        tmp_flow = c_eco_flow[take_r] + c_eco_out[give_r] * c_flow_A_vec[fO]
        @rep_elem tmp_flow ⇒ (c_eco_flow, take_r, :cEco)
        # efflux from non vegetation pools
        if give_r ∉ getZix(cVeg, helpers.pools.zix.cVeg)
            tmp_efflux = c_eco_efflux[give_r] + c_eco_out[give_r] * (1.0 - c_flow_A_vec[fO])
            @rep_elem tmp_efflux ⇒ (c_eco_efflux, give_r, :cEco)
        end
    end
    # for jix = 1:length(p_taker)
    # c_taker = p_taker[jix]
    # c_giver = p_giver[jix]
    # c_flow = c_flow_A_vec(c_taker, c_giver)
    # take_flow = c_eco_flow[c_taker]
    # give_flow = c_eco_out[c_giver]
    # c_eco_flow[c_taker] = take_flow + give_flow * c_flow
    # end
    ## balance
    ΔcEco = c_eco_flow .+ c_eco_influx .- c_eco_out
    cEco = cEco .+ c_eco_flow .+ c_eco_influx .- c_eco_out

    ## compute RA & RH
    npp = sum(c_eco_npp)
    backNEP = sum(cEco) - sum(cEco_prev)
    auto_respiration = gpp - npp
    eco_respiration = gpp - backNEP
    hetero_respiration = eco_respiration - auto_respiration
    nee = eco_respiration - gpp
    cEco_prev = cEco

    ## pack land variables
    @pack_nt begin
        cEco ⇒ land.pools
        (nee, npp, auto_respiration, eco_respiration, hetero_respiration) ⇒ land.fluxes
        (c_eco_efflux, c_eco_flow, c_eco_influx, c_eco_out, c_eco_npp) ⇒ land.fluxes
        cEco_prev ⇒ land.states
        ΔcEco ⇒ land.pools
    end
    return land
end

purpose(::Type{cCycle_simple}) = "Carbon cycle with components based on the simplified version of the CASA approach."

@doc """

$(getModelDocString(cCycle_simple))

---

# Extended help

*References*
 - Potter; C. S.; J. T. Randerson; C. B. Field; P. A. Matson; P. M.  Vitousek; H. A. Mooney; & S. A. Klooster. 1993. Terrestrial ecosystem  production: A process model based on global satellite & surface data.  Global Biogeochemical Cycles. 7: 811-841.

*Versions*
 - 1.0 on 28.02.2020 [sbesnard]  

*Created by*
 - ncarvalhais
"""
cCycle_simple
