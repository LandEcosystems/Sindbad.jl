export runoffSurface_indirect

#! format: off
@bounds @describe @units @timescale @with_kw struct runoffSurface_indirect{T1} <: runoffSurface
    dc::T1 = 0.01 | (0.0, 1.0) | "delayed surface runoff coefficient" | "" | ""
end
#! format: on

function compute(params::runoffSurface_indirect, forcing, land, helpers)
    ## unpack parameters
    @unpack_runoffSurface_indirect params

    ## unpack land variables
    @unpack_nt begin
        (surfaceW, ΔsurfaceW) ⇐ land.pools
        overland_runoff ⇐ land.fluxes
        n_surfaceW = surfaceW ⇐ helpers.pools.n_layers
    end

    # fraction of overland runoff that recharges the surface water & the fraction that flows out directly
    suw_recharge = overland_runoff

    # fraction of surface storage that flows out as surface runoff
    surface_runoff = dc * sum(surfaceW)

    # update the delta storage
    @add_to_elem suw_recharge ⇒ (ΔsurfaceW, 1, :surfaceW) # assumes all the recharge supplies the first surface water layer
    ΔsurfaceW = addToEachElem(ΔsurfaceW, - surface_runoff / n_surfaceW)

    ## pack land variables
    @pack_nt begin
        (surface_runoff, suw_recharge) ⇒ land.fluxes
        ΔsurfaceW ⇒ land.pools
    end
    return land
end

purpose(::Type{runoffSurface_indirect}) = "All overland runoff is collected in surface water storage first, which in turn generates indirect surface runoff."

@doc """

$(getModelDocString(runoffSurface_indirect))

---

# Extended help

*References*

*Versions*
 - 1.0 on 20.11.2019 [skoirala | @dr-ko]: combine surface_runoff_direct, Indir, suw_recharge  

*Created by*
 - skoirala | @dr-ko
"""
runoffSurface_indirect
