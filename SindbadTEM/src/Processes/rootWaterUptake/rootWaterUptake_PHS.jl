export rootWaterUptake_PHS

struct rootWaterUptake_PHS <: rootWaterUptake end

function define(params::rootWaterUptake_PHS, forcing, land, helpers)

    @unpack_nt begin
        soilW ⇐ land.pools
    end

    # SINDBAD: allocate the standard root-water-uptake flux container.
    root_water_uptake = zero(soilW)

    @pack_nt begin
        root_water_uptake ⇒ land.fluxes
    end
    return land
end

function compute(params::rootWaterUptake_PHS, forcing, land, helpers)
    @unpack_nt begin
        ΔsoilW ⇐ land.pools
        (phs_root_water_uptake, root_water_uptake) ⇐ land.fluxes
    end

    for sl ∈ eachindex(land.pools.soilW)
        uptake = _non_negative_Finite(phs_root_water_uptake[sl])
        @rep_elem uptake ⇒ (root_water_uptake, sl, :soilW)
        @add_to_elem -uptake ⇒ (ΔsoilW, sl, :soilW)
    end

    @pack_nt begin
        root_water_uptake ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end

purpose(::Type{rootWaterUptake_PHS}) = "Apply nonnegative, water-limited PHS root uptake to the soil-water pools."

@doc """

$(getModelDocString(rootWaterUptake_PHS))

---

# Extended help

*Versions*
 - 1.0 on 18.09.2026 [jzhou]

*Created by*
 - jzhou

"""
rootWaterUptake_PHS
