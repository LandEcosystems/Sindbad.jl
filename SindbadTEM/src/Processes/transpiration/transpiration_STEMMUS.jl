export transpiration_STEMMUS

struct transpiration_STEMMUS <: transpiration end

function compute(params::transpiration_STEMMUS, forcing, land, helpers)
    @unpack_nt stemmus_transpiration ⇐ land.diagnostics
    transpiration = stemmus_transpiration
    @pack_nt transpiration ⇒ land.fluxes
    return land
end

purpose(::Type{transpiration_STEMMUS}) =
    "Transpiration diagnosed by the coupled daily STEMMUS-PHS gas-exchange iteration."

@doc """
$(getModelDocString(transpiration_STEMMUS))

Unlike transpiration_PHS, this adapter does not replace canopy transpiration
with the sum of root uptake. That follows STEMMUS-SCOPE, where canopy latent
heat determines transpiration and the layer root sink is diagnosed separately.
"""
transpiration_STEMMUS
