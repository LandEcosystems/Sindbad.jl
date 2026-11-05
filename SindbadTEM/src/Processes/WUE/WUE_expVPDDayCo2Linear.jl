export WUE_expVPDDayCo2Linear

#! format: off
@bounds @describe @units @timescale @with_kw struct WUE_expVPDDayCo2Linear{T1,T2,T3} <: WUE
    WUE_one_hpa::T1 = 9.2 | (2.0, 20.0) | "WUE at 1 hpa VPD and the reference ambient CO2" | "gC/mmH2O" | ""
    κ::T2 = 0.4 | (0.06, 0.7) | "sensitivity of WUE to VPD" | "kPa-1" | ""
    ref_ambient_CO2::T3 = 380.0 | (-Inf, Inf) | "ambient CO2 at which the CO2 effect is one" | "ppm" | ""
end
#! format: on

function compute(params::WUE_expVPDDayCo2Linear, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_WUE_expVPDDayCo2Linear params
    @unpack_nt f_VPD_day ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        ambient_CO2 ⇐ land.states
    end

    ## calculate variables
    WUENoCO2 = WUE_one_hpa * exp(κ * -(f_VPD_day))
    # WUE is proportional to ambient CO2 at a fixed ratio of leaf internal to
    # ambient CO2
    WUE = WUENoCO2 * ambient_CO2 / ref_ambient_CO2

    ## pack land variables
    @pack_nt (WUENoCO2, WUE) ⇒ land.diagnostics
    return land
end

purpose(::Type{WUE_expVPDDayCo2Linear}) = "Calculates WUE as a function of WUE at 1 hPa, daily mean VPD, and a CO₂ effect proportional to ambient CO₂."

@doc """

$(getModelDocString(WUE_expVPDDayCo2Linear))

---

# Extended help

The CO2 effect is ambient_CO2 / ref_ambient_CO2. With a fixed ratio χ of leaf
internal to ambient CO2, assimilation is g_s Ca (1 - χ) and transpiration is
1.6 g_s VPD, so WUE grows in proportion to Ca. This is the assumption of
gppVPD_Farquhar1980, whose ref_ambient_CO2 should have the same value. The effect has
no free parameter. ref_ambient_CO2 is not meant to be calibrated, since only its
ratio to WUE_one_hpa is identifiable.

*References*

*Versions*
 - 1.0 on 03.11.2026 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko
"""
WUE_expVPDDayCo2Linear
