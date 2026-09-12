export autoRespiration_Thornley2000B

#! format: off
@bounds @describe @units @timescale @with_kw struct autoRespiration_Thornley2000B{T1,T2} <: autoRespiration
    RMN::T1 = 0.009085714285714286 | (0.0009085714285714285, 0.09085714285714286) | "Nitrogen efficiency rate of maintenance respiration" | "gC/gN/day" | "day"
    YG::T2 = 0.75 | (0.0, 1.0) | "growth yield coefficient, or growth efficiency. Loosely: (1-YG)*GPP is growth respiration" | "gC/gC" | ""
end
#! format: on

function define(params::autoRespiration_Thornley2000B, forcing, land, helpers)
    @unpack_nt begin
        cEco ⇐ land.pools
    end
    c_eco_efflux = zero(cEco)
    k_respiration_maintain = one.(cEco)
    k_respiration_maintain_su = one.(cEco)
    auto_respiration_growth = zero(cEco)
    auto_respiration_maintain = zero(cEco)

    ## pack land variables
    @pack_nt begin
        (k_respiration_maintain, k_respiration_maintain_su) ⇒ land.diagnostics
        (auto_respiration_growth, auto_respiration_maintain, c_eco_efflux) ⇒ land.fluxes
    end
    return land
end

function compute(params::autoRespiration_Thornley2000B, forcing, land, helpers)
    ## unpack parameters
    @unpack_autoRespiration_Thornley2000B params

    ## unpack land variables
    @unpack_nt begin
        (k_respiration_maintain, k_respiration_maintain_su) ⇐ land.diagnostics
        (c_eco_efflux, auto_respiration_growth, auto_respiration_maintain) ⇐ land.fluxes
        (cEco, cVeg) ⇐ land.pools
        gpp ⇐ land.fluxes
        C_to_N_cVeg ⇐ land.diagnostics
        cVegZix = cVeg ⇐ helpers.pools.zix
        (auto_respiration_f_airT, c_allocation) ⇐ land.diagnostics
    end
    # adjust nitrogen efficiency rate of maintenance respiration to the current
    # model time step
    zix = getZix(cVeg, cVegZix)
    for ix ∈ zix

        # compute maintenance & growth respiration terms for each vegetation pool
        # according to MODEL B - growth respiration is given priority

        # scalars of maintenance respiration for models A; B & C
        # km is the maintenance respiration coefficient [d-1]
        k_respiration_maintain_ix = at_most_one(one(eltype(C_to_N_cVeg)) / C_to_N_cVeg[ix] * RMN * auto_respiration_f_airT)
        k_respiration_maintain_su_ix = k_respiration_maintain[ix] * YG

        # growth respiration: R_g = (1.0 - YG) * (GPP * allocationToPool - R_m)
        RA_G_ix = (one(YG) - YG) * (gpp * c_allocation[ix])

        # maintenance respiration: R_m = km * (C + YG * GPP * allocationToPool)
        RA_M_ix = k_respiration_maintain_ix * (cEco[ix] + YG * gpp * c_allocation[ix])

        # no negative growth or maintenance respiration
        RA_G_ix = at_least_zero(RA_G_ix)
        RA_M_ix = at_least_zero(RA_M_ix)

        # total respiration per pool: R_a = R_m + R_g
        cEcoEfflux_ix = RA_M_ix + RA_G_ix
        @rep_elem cEcoEfflux_ix ⇒ (c_eco_efflux, ix)
        @rep_elem k_respiration_maintain_ix ⇒ (k_respiration_maintain, ix)
        @rep_elem k_respiration_maintain_su_ix ⇒ (k_respiration_maintain_su, ix)
        @rep_elem RA_M_ix ⇒ (auto_respiration_maintain, ix)
        @rep_elem RA_G_ix ⇒ (auto_respiration_growth, ix)
    end
    ## pack land variables
    @pack_nt begin
        (k_respiration_maintain, k_respiration_maintain_su) ⇒ land.diagnostics
        (auto_respiration_growth, auto_respiration_maintain, c_eco_efflux) ⇒ land.fluxes
    end
    return land
end

purpose(::Type{autoRespiration_Thornley2000B}) = "Calculates autotrophic maintenance and growth respiration using Thornley and Cannell (2000) Model B, where growth respiration is prioritized."


@doc """

    $(getModelDocString(autoRespiration_Thornley2000B))   

---

# Extended help

*References*
 - Amthor, J. S. (2000), The McCree-de Wit-Penning de Vries-Thornley  respiration paradigms: 30 years later, Ann Bot-London, 86[1], 1-20.  Ryan, M. G. (1991), Effects of Climate Change on Plant Respiration, Ecol  Appl, 1[2], 157-167.
 - Thornley, J. H. M., & M. G. R. Cannell [2000], Modelling the components  of plant respiration: Representation & realism, Ann Bot-London, 85[1]  55-67.

*Versions*
 - 1.0 on 06.05.2022 [ncarvalhais/skoirala]: cleaned up the code

*Created by*
 - ncarvalhais

*Notes*
 - Questions - practical - leave raAct per pool; | make a field land.fluxes.ra  that has all the autotrophic respiration components together?  
"""
autoRespiration_Thornley2000B
