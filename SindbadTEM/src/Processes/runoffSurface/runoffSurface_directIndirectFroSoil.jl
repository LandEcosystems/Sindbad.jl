export runoffSurface_directIndirectFroSoil

#! format: off
@bounds @describe @units @timescale @with_kw struct runoffSurface_directIndirectFroSoil{T1,T2} <: runoffSurface
    dc::T1 = 0.01 | (0.0, 1.0) | "delayed surface runoff coefficient" | "" | ""
    rf::T2 = 0.5 | (0.0, 1.0) | "fraction of overland runoff that recharges the surface water storage" | "" | ""
end
#! format: on

function compute(params::runoffSurface_directIndirectFroSoil, forcing, land, helpers)
    ## unpack parameters
    @unpack_runoffSurface_directIndirectFroSoil params

    ## unpack land variables
    @unpack_nt begin
        frac_frozen_soil ⇐ land.states
        surfaceW ⇐ land.pools
        ΔsurfaceW ⇐ land.pools
        overland_runoff ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
        n_surfaceW = surfaceW ⇐ helpers.pools.n_layers
    end
    # fraction of overland runoff that flows out directly
    fracFastQ = (o_one - rf) * (o_one - frac_frozen_soil) + frac_frozen_soil

    surface_runoff_direct = fracFastQ * overland_runoff

    # fraction of surface storage that flows out irrespective of input
    suw_recharge = rf * overland_runoff
    surface_runoff_indirect = dc * sum(surfaceW + ΔsurfaceW)

    # get the total surface runoff
    surface_runoff = surface_runoff_direct + surface_runoff_indirect

    # update the delta storage
    @add_to_elem suw_recharge ⇒ (ΔsurfaceW, 1, :surfaceW) # assumes all the recharge supplies the first surface water layer
    ΔsurfaceW = addToEachElem(ΔsurfaceW, - surface_runoff_indirect / n_surfaceW)

    ## pack land variables
    @pack_nt begin
        (surface_runoff, surface_runoff_direct, surface_runoff_indirect, suw_recharge) ⇒ land.fluxes
        ΔsurfaceW ⇒ land.pools
    end
    return land
end

purpose(::Type{runoffSurface_directIndirectFroSoil}) = "Surface runoff as the sum of the direct fraction of overland runoff and the indirect fraction of surface water storage, with the direct fraction additionally dependent on the frozen fraction of the grid."

@doc """

$(getModelDocString(runoffSurface_directIndirectFroSoil))

---

# Extended help

*References*

*Versions*
 - 1.0 on 03.12.2020 [ttraut]  

*Created by*
 - ttraut
"""
runoffSurface_directIndirectFroSoil
