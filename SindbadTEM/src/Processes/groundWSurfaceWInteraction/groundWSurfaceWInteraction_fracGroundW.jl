export groundWSurfaceWInteraction_fracGroundW

#! format: off
@bounds @describe @units @timescale @with_kw struct groundWSurfaceWInteraction_fracGroundW{T1} <: groundWSurfaceWInteraction
    k_gw_to_suw::T1 = 0.5 | (0.0001, 0.999) | "scale parameter for drainage from wGW to wSurf" | "fraction" | ""
end
#! format: on

function compute(params::groundWSurfaceWInteraction_fracGroundW, forcing, land, helpers)
    ## unpack parameters
    @unpack_groundWSurfaceWInteraction_fracGroundW params

    ## unpack land variables
    @unpack_nt begin
        (groundW, surfaceW) ⇐ land.pools
        (ΔsurfaceW, ΔgroundW) ⇐ land.pools
        n_surfaceW = surfaceW ⇐ helpers.pools.n_layers
        n_groundW = groundW ⇐ helpers.pools.n_layers
    end

    ## calculate variables
    gw_to_suw_flux = k_gw_to_suw * totalS(groundW, ΔgroundW)

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


purpose(::Type{groundWSurfaceWInteraction_fracGroundW}) = "Depletion of groundwater to surface water as a fraction of groundwater storage."

@doc """

$(getModelDocString(groundWSurfaceWInteraction_fracGroundW))

---

# Extended help

*References*

*Versions*
 - 1.0 on 04.02.2020 [ttraut]

*Created by*
 - ttraut
"""
groundWSurfaceWInteraction_fracGroundW
