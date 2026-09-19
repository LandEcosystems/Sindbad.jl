export rootWaterUptake_proportion

struct rootWaterUptake_proportion <: rootWaterUptake end

function define(params::rootWaterUptake_proportion, forcing, land, helpers)

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

function compute(params::rootWaterUptake_proportion, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        PAW ⇐ land.states
        (soilW, ΔsoilW) ⇐ land.pools
        transpiration ⇐ land.fluxes
        root_water_uptake ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
        tolerance ⇐ helpers.numbers
    end
    # get the transpiration
    # to_uptake = o_one * transpiration
    PAWTotal = sum(PAW)
    to_uptake = at_least_zero(oftype(PAWTotal, transpiration))

    # extract from top to bottom
    for sl ∈ eachindex(land.pools.soilW)
        uptake_proportion = to_uptake * safe_divide(PAW[sl], PAWTotal)
        @rep_elem uptake_proportion ⇒ (root_water_uptake, sl)
        @add_to_elem -root_water_uptake[sl] ⇒ (ΔsoilW, sl, :soilW)
    end
    # pack land variables
    @pack_nt begin
        root_water_uptake ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end


purpose(::Type{rootWaterUptake_proportion}) = "Root uptake from each soil layer proportional to the relative plant water availability in the layer."

@doc """

$(getModelDocString(rootWaterUptake_proportion))

---

# Extended help

*References*

*Versions*
 - 1.0 on 13.03.2020 [ttraut]

*Created by*
 - ttraut

*Notes*
 - assumes that the uptake from each layer remains proportional to the root fraction
"""
rootWaterUptake_proportion
