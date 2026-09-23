export gpp_CLM

struct gpp_CLM <: gpp end

function compute(params::gpp_CLM, forcing, land, helpers)
    @unpack_nt clm_gpp ⇐ land.diagnostics
    gpp = clm_gpp
    @pack_nt gpp ⇒ land.fluxes
    return land
end

purpose(::Type{gpp_CLM}) =
    "Daily GPP solved by the coupled single-leaf Farquhar-Medlyn-CLM hydraulic iteration."

@doc """
$(getModelDocString(gpp_CLM))

Publishes the GPP diagnosed inside `plantHydraulics_CLM`. This pathway is
independent of SINDBAD `gppPotential`, climate multipliers, and `gpp_demand`.
"""
gpp_CLM
