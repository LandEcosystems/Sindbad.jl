export rootWaterUptake_STEMMUS

struct rootWaterUptake_STEMMUS <: rootWaterUptake end

function define(params::rootWaterUptake_STEMMUS, forcing, land, helpers)
    @unpack_nt soilW ⇐ land.pools
    root_water_uptake = zero(soilW)
    @pack_nt root_water_uptake ⇒ land.fluxes
    return land
end

function compute(params::rootWaterUptake_STEMMUS, forcing, land, helpers)
    @unpack_nt begin
        ΔsoilW ⇐ land.pools
        (stemmus_root_water_uptake, root_water_uptake) ⇐ land.fluxes
    end
    @inbounds for sl in eachindex(root_water_uptake)
        uptake = stemmus_root_water_uptake[sl]
        @rep_elem uptake ⇒ (root_water_uptake, sl, :soilW)
        @add_to_elem -uptake ⇒ (ΔsoilW, sl, :soilW)
    end
    @pack_nt begin
        root_water_uptake ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end

purpose(::Type{rootWaterUptake_STEMMUS}) =
    "Apply the nonnegative, layer-resolved STEMMUS-PHS root uptake to SINDBAD soil water."

@doc """
$(getModelDocString(rootWaterUptake_STEMMUS))

The MATLAB PHS branch replaces negative root uptake with a tiny positive
number. This adapter applies the resulting daily layer flux to the SINDBAD
soil-water tendency.
"""
rootWaterUptake_STEMMUS
