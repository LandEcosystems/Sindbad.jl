export vegAvailableWater_rootWaterEfficiency

struct vegAvailableWater_rootWaterEfficiency <: vegAvailableWater end

function define(params::vegAvailableWater_rootWaterEfficiency, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        soilW ⇐ land.pools
    end

    PAW = zero(soilW)

    ## pack land variables
    @pack_nt PAW ⇒ land.states
    return land
end

function compute(params::vegAvailableWater_rootWaterEfficiency, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        w_wp ⇐ land.properties
        root_water_efficiency ⇐ land.diagnostics
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        PAW ⇐ land.states
    end
    # @debug "vegAvailableWater_rootWaterEfficiency"
    # @debug ΔsoilW
    for sl ∈ eachindex(soilW)
        PAW_sl = root_water_efficiency[sl] * (at_least_zero(soilW[sl] + ΔsoilW[sl] - w_wp[sl]))
        @rep_elem PAW_sl ⇒ (PAW, sl, :soilW)
    end
    # @show soilW .+ ΔsoilW, root_water_efficiency, w_wp, PAW

    @pack_nt PAW ⇒ land.states
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
