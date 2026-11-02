export gppVPD_Farquhar

#! format: off
@bounds @describe @units @timescale @with_kw struct gppVPD_Farquhar{T1,T2,T3,T4,T5,T6} <: gppVPD
    κ::T1 = 0.4 | (0.06, 0.7) | "sensitivity of GPP to VPD" | "kPa-1" | ""
    χ::T2 = 0.7 | (0.4, 0.9) | "ratio of leaf internal to ambient CO2" | "" | ""
    ref_ambient_CO2::T3 = 380.0 | (300.0, 500.0) | "ambient CO2 at which the CO2 effect is one" | "ppm" | ""
    Γ_star_25::T4 = 42.75 | (-Inf, Inf) | "CO2 compensation point at 25 °C" | "ppm" | ""
    ΔH_Γ_star::T5 = 37830.0 | (-Inf, Inf) | "activation energy of the CO2 compensation point" | "J mol-1" | ""
    gas_constant::T6 = 8.314 | (-Inf, Inf) | "universal gas constant" | "J mol-1 K-1" | ""
end
#! format: on

function compute(params::gppVPD_Farquhar, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppVPD_Farquhar params
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

    ## light limited CO2 response, relative to the reference CO2 at the same Γ_star
    # so that the temperature of Γ_star is not a stress on GPP here
    m_CO2 = at_least_zero(χ * ambient_CO2 - Γ_star) / (χ * ambient_CO2 + t_two * Γ_star)
    m_ref = at_least_zero(χ * ref_ambient_CO2 - Γ_star) / (χ * ref_ambient_CO2 + t_two * Γ_star)
    gpp_f_co2 = safe_divide(m_CO2, m_ref)

    ## VPD stress of Maekelae (2008) and the CO2 effect
    gpp_f_vpd = exp(-κ * f_VPD_day) * gpp_f_co2

    ## pack land variables
    @pack_nt (gpp_f_co2, gpp_f_vpd) ⇒ land.diagnostics
    return land
end

purpose(::Type{gppVPD_Farquhar}) = "VPD stress on GPP potential based on Maekelae (2008), with the CO₂ effect of light limited C3 photosynthesis of Farquhar et al. (1980)."

@doc """

$(getModelDocString(gppVPD_Farquhar))

---

# Extended help

The VPD stress is exp(-κ VPD) as in gppVPD_Maekelae2008. It is multiplied by the
CO2 effect m(Ca) / m(ref_ambient_CO2), where m = (Ci - Γ*) / (Ci + 2Γ*) is the CO2
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
gppVPD_Farquhar
