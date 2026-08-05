export snowMelt_Tair

#! format: off
@bounds @describe @units @timescale @with_kw struct snowMelt_Tair{T1} <: snowMelt
    rate::T1 = 1.0 | (0.1, 10.0) | "snow melt rate" | "mm/°C" | "day"
end
#! format: on

function compute(params::snowMelt_Tair, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_snowMelt_Tair params
    @unpack_nt f_airT ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        (WBP, frac_snow) ⇐ land.states
        snowW ⇐ land.pools
        ΔsnowW ⇐ land.pools
        z_zero ⇐ land.constants
        n_snowW = snowW ⇐ helpers.pools.n_layers
    end
    # effect of temperature on snow melt = snowMeltRate * f_airT
    pRate = rate
    Tterm = at_least_zero(pRate * f_airT)

    # snow melt [mm/day] is calculated as a simple function of temperature & scaled with the snow covered fraction
    snow_melt = min(totalS(snowW, ΔsnowW), Tterm * frac_snow)

    # divide snowmelt loss equally from all layers
    ΔsnowW = addToEachElem(ΔsnowW, snow_melt / n_snowW)

    # a Water Balance Pool variable that tracks how much water is still "available" | ""
    WBP = WBP + snow_melt

    ## pack land variables
    @pack_nt begin
        snow_melt ⇒ land.fluxes
        Tterm ⇒ land.fluxes
        WBP ⇒ land.states
        ΔsnowW ⇒ land.pools
    end
    return land
end

purpose(::Type{snowMelt_Tair}) = "Snowmelt as a function of air temperature."

@doc """

$(getModelDocString(snowMelt_Tair))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code  

*Created by*
 - mjung

*Notes*
 - may not be working well for longer time scales (like for weekly |  longer time scales). Warnings needs to be set accordingly.
 - may not be working well for longer time scales (like for weekly |  longer time scales). Warnings needs to be set accordingly.  
"""
snowMelt_Tair
