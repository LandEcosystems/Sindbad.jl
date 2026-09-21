export cDieBack_ImplicitResprout

#! format: off
@bounds @describe @units @timescale @with_kw struct cDieBack_ImplicitResprout{T1} <: cCycleDisturbance
    frac_reserve_survival::T1 = 1.0 | (0.0, 1.0) | "fraction of the reserve carbon pools that survives upon a disturbance" | "" | ""
end
#! format: on

function define(params::cDieBack_ImplicitResprout, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools

    # initialize disturbance outputs
    c_disturbance_mortality = zero(cEco)
    c_disturbance_flow = zero(cEco)
    c_disturbance_efflux = zero(cEco)
    @pack_nt begin 
        (c_disturbance_mortality, c_disturbance_flow, c_disturbance_efflux) ⇒ land.diagnostics
    end
    return land
end

function compute(params::cDieBack_ImplicitResprout, forcing, land, helpers)
    ## unpack forcing
    @unpack_nt f_dist_intensity ⇐ forcing
    @unpack_cDieBack_ImplicitResprout params

    ## unpack land variables
    @unpack_nt begin
        (c_giver, c_taker, c_flow_QP_vec, zix_cHeterotrophic, zix_cVeg) ⇐ land.cCycleBase
        cEco ⇐ land.pools
        c_remain ⇐ land.states
        c_model ⇐ land.models
        (c_disturbance_mortality, c_disturbance_flow, c_disturbance_efflux) ⇐ land.diagnostics
    end
    if f_dist_intensity > z_zero
        for fO ∈ c_flow_order
            c_giver[fO] ∈ zix_cVeg || continue
            frac_lives = c_giver[fO] ∈ helpers.pools.zix.cVegReserve ? frac_reserve_survival : zero(frac_reserve_survival)
            cLoss = at_least_zero(cEco[c_giver[fO]] - c_remain * frac_lives) * f_dist_intensity * c_flow_QP_vec[fO]
            #=
            # deplete pool
            @add_to_elem -cLoss ⇒ (cEco, c_giver[fO])
            # transfer to litter
            @add_to_elem cLoss ⇒ (cEco, c_taker[fO])
            =#
            # track mortality
            @add_to_elem cLoss ⇒ (c_disturbance_mortality, c_giver[fO])
            @add_to_elem cLoss ⇒ (c_disturbance_flow, c_taker[fO])
        end
        # land = adjustPackPoolComponents(land, helpers, c_model)
    end
    ## pack land variables
    @pack_nt begin 
        (c_disturbance_mortality, c_disturbance_flow, c_disturbance_efflux) ⇒ land.diagnostics 
    end
    return land
end

purpose(::Type{cDieBack_ImplicitResprout}) = "Unspecified mortality. Could be a storm. Moves carbon in vegetation pools to their non-vegetation carbon-flow target pools during disturbance events while allowing a parameterized fraction of the reserve pool to survive."

@doc """

$(getModelDocString(cDieBack_ImplicitResprout))

---

# Extended help

This approach is called `ImplicitResprout` because post-disturbance recovery is represented 
implicitly through survival of a fraction `frac_reserve_survival` of `cVegReserve`, rather 
than through an explicit resprouting via seed pools. The non-surviving fraction follows the 
existing vegetation-to-litter flow pathways. `frac_reserve_survival = 0` reduces to 
`NoRecovery` for the reserve pool, while `frac_reserve_survival = 1` gives complete reserve 
survival.

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].

*Versions*
 - 1.0 on 23.04.2021 [skoirala | @dr-ko]
 - 1.0 on 23.04.2021 [skoirala | @dr-ko]  
 - 1.1 on 29.11.2021 [skoirala | @dr-ko]: moved the scaling parameters to  ccyclebase_gsi [land.diagnostics.ηA & land.diagnostics.ηH]  

*Created by*
 - skoirala | @dr-ko
"""
cDieBack_ImplicitResprout
