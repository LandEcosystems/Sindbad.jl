export snowMelt_TairRn

#! format: off
@bounds @describe @units @timescale @with_kw struct snowMelt_TairRn{T1,T2} <: snowMelt
    melt_T::T1 = 3.0 | (0.01, 10.0) | "melt factor for temperature" | "mm/°C" | ""
    melt_Rn::T2 = 2.0 | (0.01, 3.0) | "melt factor for radiation" | "mm/MJ/m2" | ""
end
#! format: on

function compute(params::snowMelt_TairRn, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_snowMelt_TairRn params
    @unpack_nt (f_rn, f_airT) ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        (WBP, frac_snow) ⇐ land.states
        snowW ⇐ land.pools
        ΔsnowW ⇐ land.pools
        (z_zero, o_one) ⇐ land.constants
        n_snowW = snowW ⇐ helpers.pools.n_layers
    end

    # snowmelt [mm/day] is calculated as a simple function of temperature & radiation & scaled with the snow covered fraction
    tmp_T = f_airT * melt_T
    tmp_Rn = at_least_zero(f_rn * melt_Rn)
    potential_snow_melt = (tmp_T + tmp_Rn) * frac_snow

    # potential snow melt if T > 0.0 deg C
    potential_snow_melt = ifelse(f_airT > z_zero, potential_snow_melt, zero(potential_snow_melt))
    snow_melt = min(totalS(snowW, ΔsnowW), potential_snow_melt)

    # divide snowmelt loss equally from all layers
    ΔsnowW = addToEachElem(ΔsnowW, -snow_melt / n_snowW)

    # a Water Balance Pool variable that tracks how much water is still "available" | ""
    WBP = WBP + snow_melt

    ## pack land variables
    @pack_nt begin
        snow_melt ⇒ land.fluxes
        potential_snow_melt ⇒ land.fluxes
        WBP ⇒ land.states
        ΔsnowW ⇒ land.pools
    end
    return land
end

purpose(::Type{snowMelt_TairRn}) = "Snowmelt based on temperature and net radiation when air temperature exceeds 0°C."

@doc """

$(getModelDocString(snowMelt_TairRn))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code  

*Created by*
 - ttraut
"""
snowMelt_TairRn
