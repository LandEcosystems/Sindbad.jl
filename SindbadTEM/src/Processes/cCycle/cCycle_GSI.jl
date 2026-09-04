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
    # save the zix for cVeg, cLit, cSoil, and cProducts
    zix_cVeg = helpers.pools.zix.cVeg
    zix_cLit = helpers.pools.zix.cLit
    zix_cSoil = helpers.pools.zix.cSoil
    zix_cProducts = helpers.pools.zix.cProducts

    zix_cLit_cSoil_cProducts = (zix_cLit..., zix_cSoil..., zix_cProducts...)
    zix_cVeg_cLit_cSoil = (zix_cVeg..., zix_cLit..., zix_cSoil...)
    zix_cLit_cSoil = (zix_cLit..., zix_cSoil...)
    ## pack land variables
    @pack_nt begin
        (c_eco_flow, c_eco_influx, c_eco_out, c_eco_npp, zero_c_eco_flow, zero_c_eco_influx) ⇒ land.fluxes
        cEco_prev ⇒ land.states
        ΔcEco ⇒ land.pools
        (zix_cLit_cSoil_cProducts, zix_cVeg_cLit_cSoil, zix_cLit_cSoil) ⇒ land.cCycle
    end
    return land
end

function compute(params::cCycle_GSI, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        (c_allocation, c_eco_k, c_flow_A_vec, c_flow_ME_vec, c_flow_QP_vec) ⇐ land.diagnostics
        (c_eco_efflux, c_eco_flow, c_eco_influx, c_eco_out, c_eco_npp, zero_c_eco_flow, zero_c_eco_influx) ⇐ land.fluxes
        (cEco, cVeg, ΔcEco) ⇐ land.pools
        cEco_prev ⇐ land.states
        gpp ⇐ land.fluxes
        (c_flow_order, c_giver, c_taker) ⇐ land.cCycleBase
        c_model ⇐ land.models
        (zix_cLit_cSoil_cProducts, zix_cVeg_cLit_cSoil, zix_cLit_cSoil) ⇐ land.cCycle
    end
    zix_cProducts = helpers.pools.zix.cProducts

    ## reset ecoflow and influx to be zero at every time step
    @rep_vec c_eco_flow ⇒ helpers.pools.zeros.cEco
    @rep_vec c_eco_influx ⇒ helpers.pools.zeros.cEco
    # @rep_vec ΔcEco ⇒ ΔcEco .* z_zero

    # reset the c_eco_efflux to zero, except for cVeg
    for zix ∈ zix_cLit_cSoil_cProducts
        tmp = zero(c_eco_efflux[zix])
        @rep_elem tmp ⇒ (c_eco_efflux, zix, :cEco)
    end

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
    for (take_r, give_r, A_value, QP_value, ME_value) ∈ zip(c_taker, c_giver, c_flow_A_vec, c_flow_QP_vec, c_flow_ME_vec)
        tmp_out = c_eco_out[give_r] * A_value * QP_value
        tmp_flow = c_eco_flow[take_r] + tmp_out * ME_value
        tmp_efflux = c_eco_efflux[give_r] + tmp_out * (one(ME_value) - ME_value)
        @rep_elem tmp_flow ⇒ (c_eco_flow, take_r, :cEco)
        @rep_elem tmp_efflux ⇒ (c_eco_efflux, give_r, :cEco)
    end

    # balance
    for cl ∈ eachindex(cEco)
        ΔcEco_cl = c_eco_flow[cl] + c_eco_influx[cl] - c_eco_out[cl]
        @add_to_elem ΔcEco_cl ⇒ (ΔcEco, cl, :cEco)
        cEco_cl = cEco[cl] + c_eco_flow[cl] + c_eco_influx[cl] - c_eco_out[cl]
        @rep_elem cEco_cl ⇒ (cEco, cl, :cEco)
    end

    # compute total fluxes
    npp = totalS(c_eco_npp)
    auto_respiration = gpp - npp

    eco_respiration = totalS_indices(c_eco_efflux, zix_cVeg_cLit_cSoil)

    hetero_respiration = totalS_indices(c_eco_efflux, zix_cLit_cSoil)

    product_respiration = totalS_indices(c_eco_efflux, zix_cProducts)


    # eco_respiration = sum(
    #     c_eco_efflux[i]
    #         for zix in zix_cVeg_cLit_cSoil
    #             for i in zix
    #     )
    
    # hetero_respiration = sum(
    #     c_eco_efflux[i]
    #         for zix in zix_cLit_cSoil
    #             for i in zix
    #     )

    # product_respiration = sum(
    #     c_eco_efflux[i]
    #         for zix in zix_cProducts
    #             for i in zix
    #     )
    
    nee = eco_respiration - gpp
    nbp = - (eco_respiration + product_respiration - gpp)

    @rep_vec cEco_prev ⇒ cEco
    @pack_nt cEco ⇒ land.pools

    land = adjustPackPoolComponents(land, helpers, c_model)
    # setComponentFromMainPool(land, helpers, helpers.pools.vals.self.cEco, helpers.pools.vals.all_components.cEco, helpers.pools.vals.zix.cEco)

    # pack land variables
    @pack_nt begin
        (nee, npp, auto_respiration, eco_respiration, hetero_respiration, product_respiration, nbp) ⇒ land.fluxes
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
