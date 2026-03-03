export vegAvailableWater_rootWaterEfficiency

struct vegAvailableWater_rootWaterEfficiency <: vegAvailableWater end

function define(params::vegAvailableWater_rootWaterEfficiency, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        soilW ⇐ land.pools
    end

    PAW = zero(soilW)
    w_awc_root_zone = zero(soilW)

    ## pack land variables
    @pack_nt (PAW, w_awc_root_zone) ⇒ land.states
    return land
end

function compute(params::vegAvailableWater_rootWaterEfficiency, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        w_wp ⇐ land.properties
        root_water_efficiency ⇐ land.diagnostics
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        (PAW, w_awc_root_zone) ⇐ land.states
        w_awc ⇐ land.properties
    end
    for sl ∈ eachindex(soilW)
        PAW_sl = root_water_efficiency[sl] * (at_least_zero(soilW[sl] + ΔsoilW[sl] - w_wp[sl]))
        w_awc_root_zone_sl = root_water_efficiency[sl] * w_awc[sl]  # avoid division by zero
        @rep_elem PAW_sl ⇒ (PAW, sl, :soilW)
        @rep_elem w_awc_root_zone_sl ⇒ (w_awc_root_zone, sl, :soilW)
    end

    @pack_nt (PAW, w_awc_root_zone) ⇒ land.states
    return land
end

purpose(::Type{vegAvailableWater_rootWaterEfficiency}) = "PAW as a function of soil moisture and root water extraction efficiency."

@doc """

$(getModelDocString(vegAvailableWater_rootWaterEfficiency))

---

# Extended help

*References*

*Versions*
 - 1.0 on 21.11.2019  

*Created by*
 - skoirala | @dr-ko
"""
vegAvailableWater_rootWaterEfficiency
