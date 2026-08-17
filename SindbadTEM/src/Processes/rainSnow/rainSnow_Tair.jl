export rainSnow_Tair

#! format: off
@bounds @describe @units @timescale @with_kw struct rainSnow_Tair{T1} <: rainSnow
    airT_thres::T1 = 0.0 | (-5.0, 5.0) | "threshold for separating rain and snow" | "°C" | ""
end
#! format: on

function compute(params::rainSnow_Tair, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_rainSnow_Tair params
    @unpack_nt (f_rain, f_airT) ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        snowW ⇐ land.pools
        ΔsnowW ⇐ land.pools
    end
    is_snow = f_airT < airT_thres
    rain = ifelse(is_snow, zero(f_rain), f_rain)
    snow = ifelse(is_snow, f_rain, zero(f_rain))
    ## calculate variables
    precip = rain + snow

    # add snowfall to snowpack of the first layer
    @add_to_elem snow ⇒ (ΔsnowW, 1, :snowW)
    ## pack land variables
    @pack_nt begin
        (precip, rain, snow) ⇒ land.fluxes
        ΔsnowW ⇒ land.pools
    end
    return land
end

purpose(::Type{rainSnow_Tair}) = "Rain and snow partitioning based on a temperature threshold."

@doc """

$(getModelDocString(rainSnow_Tair))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]: creation of approach  

*Created by*
 - skoirala | @dr-ko
"""
rainSnow_Tair
