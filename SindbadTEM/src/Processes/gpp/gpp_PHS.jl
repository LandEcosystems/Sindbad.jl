export gpp_PHS

struct gpp_PHS <: gpp end

function compute(params::gpp_PHS, forcing, land, helpers)
    @unpack_nt begin
        f_PAR ⇐ forcing
        fAPAR ⇐ land.states
        (gpp_farquhar, Ac_gC, Aj_gC) ⇐ land.diagnostics
        z_zero ⇐ land.constants
    end

    gpp = gpp_farquhar

    # supply and demand should be Aj and Ac.
    gpp_s = Ac_gC
    gpp_d = Aj_gC
    delta_gpp = gpp_d - gpp_s

    APAR = fAPAR * f_PAR
    lue = APAR != z_zero ? gpp / APAR : z_zero

    @pack_nt begin
        (gpp, gpp_s, gpp_d, delta_gpp) ⇒ land.fluxes
        (lue) ⇒ land.diagnostics
    end

    return land
end

purpose(::Type{gpp_PHS}) =
    "Daily GPP from the coupled Farquhar-Fick-Jarvis-PHS equilibrium."

@doc """
$(getModelDocString(gpp_PHS))

*Versions*
 - 1.0 on 18.09.2026 [jzhou]

*Created by*
 - jzhou
 
"""
gpp_PHS
