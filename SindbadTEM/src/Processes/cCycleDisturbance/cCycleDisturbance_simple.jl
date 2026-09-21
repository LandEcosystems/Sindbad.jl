export cCycleDisturbance_simple


struct cCycleDisturbance_simple <: cCycle end

function define(params::cCycleDisturbance_simple, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools

    # initialize disturbance outputs
    c_disturbance_mortality = zero(cEco)
    c_disturbance_efflux = zero(cEco)
    c_disturbance_flow = zero(cEco)
    c_fire_mortality = zero(cEco)
    c_fire_efflux = zero(cEco)
    c_fire_flow = zero(cEco)
    @pack_nt begin 
        (
            c_disturbance_mortality, c_disturbance_efflux, c_disturbance_flow, 
            c_fire_mortality, c_fire_efflux, c_fire_flow,
        ) ⇒ land.diagnostics
    end
    return land
end

function compute(params::cCycleDisturbance_simple, forcing, land, helpers)
    ## unpack forcing

    ## unpack land variables
    @unpack_nt begin
        cEco ⇐ land.pools
        (
            c_disturbance_mortality, c_disturbance_efflux, c_disturbance_flow, 
            c_fire_mortality, c_fire_efflux, c_fire_flow,
        ) ⇐ land.diagnostics
    end
    for cl ∈ eachindex(cEco)
        δDisturbance = (c_fire_flow[cl] + c_disturbance_flow[cl]) - 
            (c_disturbance_mortality[cl] + c_fire_mortality[cl]) -
            (c_disturbance_efflux[cl] + c_fire_efflux[cl])
        cEco_cl = cEco[cl] + δDisturbance
        @rep_elem cEco_cl ⇒ (cEco, cl)
    end
    @pack_nt cEco ⇒ land.pools
    land = adjustPackPoolComponents(land, helpers, c_model)

    ## pack land variables
    return land
end

purpose(::Type{cCycleDisturbance_simple}) = "Moves carbon in vegetation pools to their non-vegetation carbon-flow target pools during disturbance events while allowing a parameterized fraction of the reserve pool to survive."

@doc """

$(getModelDocString(cCycleDisturbance_simple))

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
cCycleDisturbance_simple
