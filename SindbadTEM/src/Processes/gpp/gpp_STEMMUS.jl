export gpp_STEMMUS

struct gpp_STEMMUS <: gpp end

function compute(params::gpp_STEMMUS, forcing, land, helpers)
    @unpack_nt stemmus_gpp ⇐ land.diagnostics
    gpp = stemmus_gpp
    @pack_nt gpp ⇒ land.fluxes
    return land
end

purpose(::Type{gpp_STEMMUS}) =
    "GPP diagnosed by the coupled daily STEMMUS-PHS gas-exchange iteration."

@doc """
$(getModelDocString(gpp_STEMMUS))

STEMMUS-SCOPE applies plant hydraulic stress to Vcmax inside its biochemical
model. In the daily SINDBAD coupling, the same stress scales GPP demand inside
plantHydraulics_STEMMUS and this adapter publishes the coupled result.
"""
gpp_STEMMUS
