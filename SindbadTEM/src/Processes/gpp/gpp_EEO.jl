export gpp_EEO

#! format: off
struct gpp_EEO <: gpp end
#! format: on

function compute(params::gpp_EEO, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        f_PAR ⇐ forcing ## mm day-1
        fAPAR ⇐ land.states
        (gpp_f_soilW, gpp_demand, WUE) ⇐ land.diagnostics
        (rwu_potential) ⇐ land.fluxes
        (gpp_f_cloud, gpp_f_light, gpp_f_airT, gpp_f_vpd) ⇐ land.diagnostics
    end
    
    max_water_supply = sum(rwu_potential)
    gpp = min(max_water_supply * WUE, gpp_demand * gpp_f_soilW)
    gpp_s = max_water_supply * WUE
    gpp_d = gpp_demand * gpp_f_soilW

    delta_gpp = gpp_d - gpp_s # for the coordination hypothesis, which means that the resources (light and water) are not wasted

    gpp_stress = gpp_f_airT * gpp_f_light * gpp_f_cloud * gpp_f_vpd * gpp_f_soilW

    lue = gpp / (fAPAR * f_PAR)

    ## pack land variables
    @pack_nt (gpp, gpp_s, gpp_d, delta_gpp) ⇒ land.fluxes
    @pack_nt (gpp_stress, lue) ⇒ land.diagnostics
    return land
end

purpose(::Type{gpp_EEO}) = "GPP based on the relationship of demand and supply."

@doc """

$(getModelDocString(gpp_EEO))

---

# Extended help

*References*

*Versions*
 - 1.0 on 19.09.2025 [jzhou]

*Created by*
 - jzhou

*Notes*
"""
gpp_EEO
