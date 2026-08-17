export gppAirT_TEM

#! format: off
@bounds @describe @units @timescale @with_kw struct gppAirT_TEM{T1,T2,T3} <: gppAirT
    Tmin::T1 = 5.0 | (-10.0, 15.0) | "minimum temperature at which GPP ceases" | "°C" | ""
    Tmax::T2 = 20.0 | (10.0, 45.0) | "maximum temperature at which GPP ceases" | "°C" | ""
    opt_airT::T3 = 15.0 | (5.0, 30.0) | "optimal temperature for GPP" | "°C" | ""
end
#! format: on

function compute(params::gppAirT_TEM, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppAirT_TEM params
    @unpack_nt f_airT_day ⇐ forcing
    @unpack_nt begin
        (z_zero, o_one, t_two) ⇐ land.constants
    end

    ## calculate variables
    pTmin = f_airT_day - Tmin
    pTmax = f_airT_day - Tmax
    pTScGPP = pTmin * pTmax / ((pTmin * pTmax) - (f_airT_day - opt_airT)^t_two)
    TScGPP = ifelse((f_airT_day > Tmax) | (f_airT_day < Tmin), z_zero, pTScGPP)
    gpp_f_airT = clamp_zero_one(TScGPP)

    ## pack land variables
    @pack_nt gpp_f_airT ⇒ land.diagnostics
    return land
end

purpose(::Type{gppAirT_TEM}) = "Temperature effect on GPP based on the TEM model."

@doc """

$(getModelDocString(gppAirT_TEM))

---

# Extended help

*References*

*Versions*
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]: documentation & clean up  

*Created by*
 - ncarvalhais

*Notes*
"""
gppAirT_TEM
