export runoffSurface_directIndirect

#! format: off
@bounds @describe @units @timescale @with_kw struct runoffSurface_directIndirect{T1,T2} <: runoffSurface
    dc::T1 = 0.01 | (0.0001, 1.0) | "delayed surface runoff coefficient" | "" | ""
    rf::T2 = 0.5 | (0.0001, 1.0) | "fraction of overland runoff that recharges the surface water storage" | "" | ""
end
#! format: on

function compute(params::runoffSurface_directIndirect, forcing, land, helpers)
    ## unpack parameters
    @unpack_runoffSurface_directIndirect params

    ## unpack land variables
    @unpack_nt begin
        surfaceW ⇐ land.pools
        ΔsurfaceW ⇐ land.pools
        overland_runoff ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
        n_surfaceW = surfaceW ⇐ helpers.pools.n_layers
    end
    # fraction of overland runoff that recharges the surface water & the
    # fraction that flows out directly
    surface_runoff_direct = (o_one - rf) * overland_runoff

    # fraction of surface storage that flows out irrespective of input
    suw_recharge = rf * overland_runoff
    surface_runoff_indirect = dc * sum(surfaceW + ΔsurfaceW)

    # get the total surface runoff
    surface_runoff = surface_runoff_direct + surface_runoff_indirect

    # update the delta storage
    @add_to_elem suw_recharge ⇒ (ΔsurfaceW, 1) # assumes all the recharge supplies the first surface water layer
    ΔsurfaceW = addToEachElem(ΔsurfaceW, - surface_runoff_indirect / n_surfaceW)

    ## pack land variables
    @pack_nt begin
        (surface_runoff, surface_runoff_direct, surface_runoff_indirect, suw_recharge) ⇒ land.fluxes
        ΔsurfaceW ⇒ land.pools
    end
    return land
end

purpose(::Type{runoffSurface_directIndirect}) = "Surface runoff as the sum of the direct fraction of overland runoff and the indirect fraction of surface water storage."

@doc """

$(getModelDocString(runoffSurface_directIndirect))

---

# Extended help

*References*

*Versions*

*Created by*
 - skoirala | @dr-ko
"""
runoffSurface_directIndirect
