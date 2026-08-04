export groundWSurfaceWInteraction_fracGradient

#! format: off
@bounds @describe @units @timescale @with_kw struct groundWSurfaceWInteraction_fracGradient{T1} <: groundWSurfaceWInteraction
    k_gw_to_suw::T1 = 0.001 | (0.0001, 0.01) | "maximum transfer rate between GW and surface water" | "/d" | ""
end
#! format: on

function compute(params::groundWSurfaceWInteraction_fracGradient, forcing, land, helpers)
    ## unpack parameters
    @unpack_groundWSurfaceWInteraction_fracGradient params

    ## unpack land variables
    @unpack_nt begin
        (ΔsurfaceW, ΔgroundW, groundW, surfaceW) ⇐ land.pools
        n_surfaceW = surfaceW ⇐ helpers.pools.n_layers
        n_groundW = groundW ⇐ helpers.pools.n_layers
    end

    ## calculate variables
    gw_to_suw_flux = k_gw_to_suw * (totalS(groundW, ΔgroundW) - totalS(surfaceW, ΔsurfaceW))

    # update the delta storages
    ΔgroundW = addToEachElem(ΔgroundW, -gw_to_suw_flux / n_groundW)
    ΔsurfaceW = addToEachElem(ΔsurfaceW, gw_to_suw_flux / n_surfaceW)

    ## pack land variables
    @pack_nt begin
        gw_to_suw_flux ⇒ land.fluxes
        (ΔsurfaceW, ΔgroundW) ⇒ land.pools
    end

    return land
end

purpose(::Type{groundWSurfaceWInteraction_fracGradient}) = "Moisture exchange between groundwater and surface water as a fraction of the difference between their storages."

@doc """

$(getModelDocString(groundWSurfaceWInteraction_fracGradient))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.11.2019 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko
"""
groundWSurfaceWInteraction_fracGradient
