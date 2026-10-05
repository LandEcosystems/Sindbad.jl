export gppAirT_Wang2014

#! format: off
@bounds @describe @units @timescale @with_kw struct gppAirT_Wang2014{T1} <: gppAirT
    Tmax::T1 = 10.0 | (5.0, 45.0) | "maximum temperature at which GPP ceases" | "°C" | ""
end
#! format: on

function compute(params::gppAirT_Wang2014, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppAirT_Wang2014 params
    @unpack_nt f_airT_day ⇐ forcing
    @unpack_nt (z_zero, o_one) ⇐ land.constants

    ## calculate variables
    gpp_f_airT = clamp_zero_one(f_airT_day / Tmax)

    ## pack land variables
    @pack_nt gpp_f_airT ⇒ land.diagnostics
    return land
end

purpose(::Type{gppAirT_Wang2014}) = "Temperature effect on GPP based on Wang (2014)."

@doc """

$(getModelDocString(gppAirT_Wang2014))

---

# Extended help

*References*
 - Wang, H., Prentice, I. C., & Davis, T. W. (2014). Biophsyical constraints on gross  primary production by the terrestrial biosphere. Biogeosciences, 11[20], 5987.

*Versions*
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]: documentation & clean up  

*Created by*
 - ncarvalhais
"""
gppAirT_Wang2014
