export gpp_coupled

struct gpp_coupled <: gpp end

function compute(params::gpp_coupled, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        f_PAR ⇐ forcing
        fAPAR ⇐ land.states
        transpiration_supply ⇐ land.diagnostics
        gpp_f_soilW ⇐ land.diagnostics
        gpp_demand ⇐ land.diagnostics
        WUE ⇐ land.diagnostics
        z_zero ⇐ land.constants
    end

    gpp_s = transpiration_supply * WUE
    gpp_d = gpp_demand * gpp_f_soilW
    delta_gpp = gpp_d - gpp_s

    gpp = min(transpiration_supply * WUE, gpp_demand * gpp_f_soilW)

    APAR = fAPAR * f_PAR
    lue = APAR != z_zero ? gpp / APAR : z_zero

    ## pack land variables
    @pack_nt begin
        (gpp, gpp_s, gpp_d, delta_gpp) ⇒ land.fluxes
        (lue) ⇒ land.diagnostics
    end
    return land
end


purpose(::Type{gpp_coupled}) = "GPP based on transpiration supply and water use efficiency (coupled)."

@doc """

$(getModelDocString(gpp_coupled))

---

# Extended help

*References*

*Versions*
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]

*Created by*
 - mjung
 - skoirala | @dr-ko

*Notes*
"""
gpp_coupled
