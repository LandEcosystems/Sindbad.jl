export gppSoilW_Stocker2020

#! format: off
@bounds @describe @units @timescale @with_kw struct gppSoilW_Stocker2020{T1,T2} <: gppSoilW
    q::T1 = 1.0 | (0.01, 4.0) | "sensitivity of GPP to soil moisture " | "" | ""
    θstar::T2 = 0.6 | (0.1, 1.0) | "" | "" | ""
end
#! format: on

function define(params::gppSoilW_Stocker2020, forcing, land, helpers)
    @unpack_gppSoilW_Stocker2020 params
    gpp_f_soilW = one(q)

    ## pack land variables
    @pack_nt gpp_f_soilW ⇒ land.diagnostics
    return land
end

function compute(params::gppSoilW_Stocker2020, forcing, land, helpers)
    ## unpack parameters
    @unpack_gppSoilW_Stocker2020 params

    ## unpack land variables
    @unpack_nt begin
        (∑w_fc, ∑w_wp) ⇐ land.properties
        soilW ⇐ land.pools
        (z_zero, o_one, t_two) ⇐ land.constants
    end
    ## calculate variables
    SM = sum(soilW)
    max_AWC = at_least_zero(∑w_fc - ∑w_wp)
    actAWC = at_least_zero(SM - ∑w_wp)
    SM_nor = at_most_one(actAWC / max_AWC)
    tf_soilW = -q * (SM_nor - θstar)^t_two + o_one
    tmp_f_soilW = ifelse(SM_nor <= θstar, tf_soilW, one(tf_soilW))
    gpp_f_soilW = clamp_zero_one(tmp_f_soilW)

    ## pack land variables
    @pack_nt gpp_f_soilW ⇒ land.diagnostics
    return land
end

purpose(::Type{gppSoilW_Stocker2020}) = "Soil moisture stress on GPP potential based on Stocker (2020)."

@doc """

$(getModelDocString(gppSoilW_Stocker2020))

---

# Extended help

*References*
 - Stocker, B. D., Wang, H., Smith, N. G., Harrison, S. P., Keenan, T. F., Sandoval, D., & Prentice, I. C. (2020). P-model v1. 0: an optimality-based light use efficiency model for simulating ecosystem gross primary production. Geoscientific Model Development, 13(3), 1545-1581.

*Versions*

*Created by*
 - ncarvalhais & Shanning Bao [sbao]

*Notes*
"""
gppSoilW_Stocker2020
