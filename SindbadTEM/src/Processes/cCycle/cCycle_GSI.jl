export cCycle_GSI

struct cCycle_GSI <: cCycle end

function define(params::cCycle_GSI, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools
    ## Instantiate variables
    c_eco_flow = zero(cEco)
    c_eco_out = zero(cEco)
    c_eco_influx = zero(cEco)
    zero_c_eco_flow = zero(c_eco_flow)
    zero_c_eco_influx = zero(c_eco_influx)
    ΔcEco = zero(cEco)
    c_eco_npp = zero(cEco)

    cEco_prev = cEco
    ## pack land variables

    @pack_nt begin
        (c_eco_flow, c_eco_influx, c_eco_out, c_eco_npp, zero_c_eco_flow, zero_c_eco_influx) ⇒ land.fluxes
        cEco_prev ⇒ land.states
        ΔcEco ⇒ land.pools
    end
    return land
end

function compute(params::cCycle_GSI, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        (c_allocation, c_eco_k, c_flow_A_vec) ⇐ land.diagnostics
        (c_eco_efflux, c_eco_flow, c_eco_influx, c_eco_out, c_eco_npp, zero_c_eco_flow, zero_c_eco_influx) ⇐ land.fluxes
        (cEco, cVeg, ΔcEco) ⇐ land.pools
        cEco_prev ⇐ land.states
        gpp ⇐ land.fluxes
        (c_flow_order, c_giver, c_taker) ⇐ land.constants
        c_model ⇐ land.models
    end
    ## reset ecoflow and influx to be zero at every time step
    @rep_vec c_eco_flow ⇒ helpers.pools.zeros.cEco
    @rep_vec c_eco_influx ⇒ helpers.pools.zeros.cEco
    # @rep_vec ΔcEco ⇒ ΔcEco .* z_zero

    ## compute losses
    for cl ∈ eachindex(cEco)
        c_eco_out_cl = min(cEco[cl], cEco[cl] * c_eco_k[cl])
        @rep_elem c_eco_out_cl ⇒ (c_eco_out, cl, :cEco)
    end

    ## gains to vegetation
    for zv ∈ getZix(cVeg, helpers.pools.zix.cVeg)
        c_eco_npp_zv = gpp * c_allocation[zv] - c_eco_efflux[zv]
        @rep_elem c_eco_npp_zv ⇒ (c_eco_npp, zv, :cEco)
        @rep_elem c_eco_npp_zv ⇒ (c_eco_influx, zv, :cEco)
    end

    # flows & losses
    # @nc; if flux order does not matter; remove# sujanq: this was deleted by simon in the version of 2020-11. Need to
    # find out why. Led to having zeros in most of the carbon pools of the
    # explicit simple
    # old before cleanup was removed during biomascat when cFlowAct was changed to gsi. But original cFlowAct CASA was writing c_flow_order. So; in biomascat; the fields do not exist & this block of code will not work.
    for fO ∈ c_flow_order
        take_r = c_taker[fO]
        give_r = c_giver[fO]
        tmp_flow = c_eco_flow[take_r] + c_eco_out[give_r] * c_flow_A_vec[fO]
        @rep_elem tmp_flow ⇒ (c_eco_flow, take_r, :cEco)
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
    for cl ∈ eachindex(cEco)
        ΔcEco_cl = c_eco_flow[cl] + c_eco_influx[cl] - c_eco_out[cl]
        @add_to_elem ΔcEco_cl ⇒ (ΔcEco, cl, :cEco)
        cEco_cl = cEco[cl] + c_eco_flow[cl] + c_eco_influx[cl] - c_eco_out[cl]
        @rep_elem cEco_cl ⇒ (cEco, cl, :cEco)
    end

    ## compute RA & RH
    npp = totalS(c_eco_npp)
    backNEP = totalS(cEco) - totalS(cEco_prev)
    auto_respiration = gpp - npp
    eco_respiration = gpp - backNEP
    hetero_respiration = eco_respiration - auto_respiration
    nee = eco_respiration - gpp

    # cEco_prev = cEco 
    # cEco_prev = cEco_prev .*z_zero.+ cEco
    @rep_vec cEco_prev ⇒ cEco
    @pack_nt cEco ⇒ land.pools

    land = adjustPackPoolComponents(land, helpers, c_model)
    # setComponentFromMainPool(land, helpers, helpers.pools.vals.self.cEco, helpers.pools.vals.all_components.cEco, helpers.pools.vals.zix.cEco)

    ## pack land variables
    @pack_nt begin
        (nee, npp, auto_respiration, eco_respiration, hetero_respiration) ⇒ land.fluxes
        (c_eco_efflux, c_eco_flow, c_eco_influx, c_eco_out, c_eco_npp) ⇒ land.fluxes
        cEco_prev ⇒ land.states
        ΔcEco ⇒ land.pools
    end
    return land
end

purpose(::Type{cCycle_GSI}) = "Carbon cycle with components based on the GSI approach, including carbon allocation, transfers, and turnover rates."

@doc """

$(getModelDocString(cCycle_GSI))

---

# Extended help

*References*
 - Potter; C. S.; J. T. Randerson; C. B. Field; P. A. Matson; P. M.  Vitousek; H. A. Mooney; & S. A. Klooster. 1993. Terrestrial ecosystem  production: A process model based on global satellite & surface data.  Global Biogeochemical Cycles. 7: 811-841.

*Versions*
 - 1.0 on 28.02.2020 [sbesnard]  

*Created by*
 - ncarvalhais
"""
cCycle_GSI