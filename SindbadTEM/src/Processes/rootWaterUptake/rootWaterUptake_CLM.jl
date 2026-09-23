export rootWaterUptake_CLM

struct rootWaterUptake_CLM <: rootWaterUptake end

function define(params::rootWaterUptake_CLM, forcing, land, helpers)
    @unpack_nt soilW ⇐ land.pools
    root_water_uptake = zero(soilW)
    @pack_nt root_water_uptake ⇒ land.fluxes
    return land
end

function compute(params::rootWaterUptake_CLM, forcing, land, helpers)
    @unpack_nt begin
        ΔsoilW ⇐ land.pools
        (clm_root_water_uptake, root_water_uptake) ⇐ land.fluxes
    end
    @inbounds for sl in eachindex(root_water_uptake)
        flux = clm_root_water_uptake[sl]
        @rep_elem flux ⇒ (root_water_uptake, sl, :soilW)
        @add_to_elem -flux ⇒ (ΔsoilW, sl, :soilW)
    end
    @pack_nt begin
        root_water_uptake ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end

purpose(::Type{rootWaterUptake_CLM}) =
    "Apply signed CLM soil-root fluxes, including hydraulic redistribution, to SINDBAD soil water."

@doc """
$(getModelDocString(rootWaterUptake_CLM))

This is the SINDBAD counterpart of CLM's hydraulic vertical transpiration sink.
It intentionally does not add the PHS daily storage bounds; use substeps when a
daily flux is large relative to layer storage.
"""
rootWaterUptake_CLM
