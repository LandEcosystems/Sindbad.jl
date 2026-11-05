export gppVPD_Farquhar1980

#! format: off
@bounds @describe @units @timescale @with_kw struct gppVPD_Farquhar1980{T1,T2,T3,T4,T5,T6,T7} <: gppVPD
    κ::T1 = 0.4 | (0.06, 0.7) | "sensitivity of GPP to VPD" | "kPa-1" | ""
    c_κ::T2 = 0.0 | (-10.0, 0.0) | "exponent of the change of the VPD sensitivity with ambient CO2" | "" | ""
    χ::T3 = 0.7 | (0.4, 0.9) | "ratio of leaf internal to ambient CO2" | "" | ""
    ref_ambient_CO2::T4 = 380.0 | (300.0, 500.0) | "ambient CO2 at which the CO2 effect is one" | "ppm" | ""
    Γ_star_25::T5 = 42.75 | (-Inf, Inf) | "CO2 compensation point at 25 °C" | "ppm" | ""
    ΔH_Γ_star::T6 = 37830.0 | (-Inf, Inf) | "activation energy of the CO2 compensation point" | "J mol-1" | ""
    gas_constant::T7 = 8.314 | (-Inf, Inf) | "universal gas constant" | "J mol-1 K-1" | ""
end
#! format: on

function compute(params::gppVPD_Farquhar1980, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppVPD_Farquhar1980 params
    @unpack_nt (f_airT_day, f_VPD_day) ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        ambient_CO2 ⇐ land.states
        t_two ⇐ land.constants
    end

    ## CO2 compensation point at the air temperature
    T_25 = oftype(Γ_star_25, 298.15)
    T_air = f_airT_day + oftype(f_airT_day, 273.15)
    Γ_star = Γ_star_25 * exp(ΔH_Γ_star * (T_air - T_25) / (T_25 * gas_constant * T_air))

    ## CO2 effect of light limited photosynthesis, normalized by its value at
    # ref_ambient_CO2 with the same Γ_star. The temperature dependence of Γ_star then
    # changes only the CO2 sensitivity and does not reduce GPP by itself.
    m_CO2 = at_least_zero(χ * ambient_CO2 - Γ_star) / (χ * ambient_CO2 + t_two * Γ_star)
    m_ref = at_least_zero(χ * ref_ambient_CO2 - Γ_star) / (χ * ref_ambient_CO2 + t_two * Γ_star)
    gpp_f_co2 = safe_divide(m_CO2, m_ref)

    ## VPD stress of Maekelae (2008), weakened at higher CO2 as in PRELES, and the
    # CO2 effect
    gpp_f_vpd = exp(-κ * f_VPD_day * (ambient_CO2 / ref_ambient_CO2)^c_κ) * gpp_f_co2

    ## pack land variables
    @pack_nt (gpp_f_co2, gpp_f_vpd) ⇒ land.diagnostics
    return land
end

purpose(::Type{gppVPD_Farquhar1980}) = "VPD stress on GPP potential based on Maekelae (2008), with the CO₂ effect of light limited C3 photosynthesis of Farquhar et al. (1980)."

@doc """

$(getModelDocString(gppVPD_Farquhar1980))

---

# Extended help

The VPD stress is exp(-κ VPD (Ca / ref_ambient_CO2)^c_κ), the stress of
gppVPD_Maekelae2008 with the CO2 modulation of gppVPD_PRELES. c_κ is at most zero,
so the VPD stress can only weaken as stomata close at higher CO2. The power stays
positive and finite at any CO2. The VPD stress is multiplied by the CO2 effect
m(Ca) / m(ref_ambient_CO2), where m = (Ci - Γ*) / (Ci + 2Γ*) is the CO2
dependence of the light limited rate of C3 photosynthesis and Ci = χ Ca. The CO2
effect is one at ref_ambient_CO2, stays positive for Ci above Γ*, and saturates at
high CO2. Its sensitivity, d ln m / d ln Ca, is about 0.4 at 400 ppm and 25 °C.

Γ* follows the air temperature with the Arrhenius function of Bernacchi et al.
(2001). The reference uses the same Γ*, so the effect is one at ref_ambient_CO2 at
every temperature, and a higher temperature only makes GPP more sensitive to CO2.

The CO2 effect is that of C3 plants. C4 plants respond much less to CO2.

*References*
 - Farquhar, G. D., von Caemmerer, S., & Berry, J. A. (1980). A biochemical model
   of photosynthetic CO2 assimilation in leaves of C3 species. Planta, 149, 78-90.
 - Bernacchi, C. J., Singsaas, E. L., Pimentel, C., Portis Jr, A. R., & Long, S. P.
   (2001). Improved temperature response functions for models of Rubisco-limited
   photosynthesis. Plant, Cell & Environment, 24, 253-259.
 - Mäkelä, A., Pulkkinen, M., Kolari, P., et al. (2008). Developing an empirical
   model of stand GPP with the LUE approach: analysis of eddy covariance data at
   five contrasting conifer sites in Europe. Global Change Biology, 14, 92-108.

*Versions*
 - 1.0 on 02.11.2026 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko
"""
gppVPD_Farquhar1980
