export transpiration_CLM

struct transpiration_CLM <: transpiration end

function compute(params::transpiration_CLM, forcing, land, helpers)
    @unpack_nt clm_transpiration ⇐ land.diagnostics
    transpiration = clm_transpiration
    @pack_nt transpiration ⇒ land.fluxes
    return land
end

purpose(::Type{transpiration_CLM}) =
    "CLM plant-hydraulic transpiration, equal to the nonnegative net soil-root flux."

@doc """
$(getModelDocString(transpiration_CLM))

Uses the total flux diagnosed by `plantHydraulics_CLM`. Negative individual
layer fluxes remain hydraulic redistribution, while the canopy transpiration
reported to the atmosphere is nonnegative as in CLM `hybrid_PHS`.
"""
transpiration_CLM
