export rootWaterUptake_topBottom

struct rootWaterUptake_topBottom <: rootWaterUptake end

function define(params::rootWaterUptake_topBottom, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        soilW ⇐ land.pools
    end
    root_water_uptake = zero(soilW)

    ## pack land variables
    @pack_nt begin
        root_water_uptake ⇒ land.fluxes
    end
    return land
end

function compute(params::rootWaterUptake_topBottom, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        PAW ⇐ land.states
        (soilW, ΔsoilW) ⇐ land.pools
        root_water_uptake ⇐ land.fluxes
        transpiration ⇐ land.fluxes
        z_zero ⇐ land.constants
    end
    PAWTotal = sum(PAW)
    to_uptake = at_least_zero(oftype(PAWTotal, transpiration))

    for sl ∈ eachindex(land.pools.soilW)
        uptake_from_layer = min(to_uptake, PAW[sl])
        @rep_elem uptake_from_layer ⇒ (root_water_uptake, sl, :soilW)
        @add_to_elem -root_water_uptake[sl] ⇒ (ΔsoilW, sl, :soilW)
        to_uptake = to_uptake - uptake_from_layer
    end

    ## pack land variables
    @pack_nt begin
        root_water_uptake ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end

purpose(::Type{rootWaterUptake_topBottom}) = "Root uptake from each soil layer from top to bottom, using maximul available water in each layer."

@doc """

$(getModelDocString(rootWaterUptake_topBottom))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.11.2019 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko

*Notes*
 - assumes that the uptake is prioritized from top to bottom; irrespective of root fraction of the layers
"""
rootWaterUptake_topBottom
