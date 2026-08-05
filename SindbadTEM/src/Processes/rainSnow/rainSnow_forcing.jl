export rainSnow_forcing

#! format: off
@bounds @describe @units @timescale @with_kw struct rainSnow_forcing{T1} <: rainSnow
    snowfall_scalar::T1 = 1.0 | (0.0, 3.0) | "scaling factor for snow fall" | "" | ""
end
#! format: on

function compute(params::rainSnow_forcing, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_rainSnow_forcing params
    @unpack_nt (f_rain, f_snow) ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        snowW ⇐ land.pools
        ΔsnowW ⇐ land.pools
    end

    ## calculate variables
    rain = f_rain
    snow = f_snow * snowfall_scalar
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

purpose(::Type{rainSnow_forcing}) = "Sets rainfall and snowfall from forcing data, with snowfall scaled if the snowfall_scalar parameter is optimized."

@doc """

$(getModelDocString(rainSnow_forcing))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]: creation of approach  

*Created by*
 - skoirala | @dr-ko
"""
rainSnow_forcing
