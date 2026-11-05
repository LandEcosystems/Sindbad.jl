export gppVPD_Farquhar1980

#! format: off
@bounds @describe @units @timescale @with_kw struct gppVPD_Farquhar1980{T1,T2,T3,T4,T5,T6} <: gppVPD
    κ::T1 = 0.4 | (0.06, 0.7) | "sensitivity of GPP to VPD at the reference ambient CO2" | "kPa-1" | ""
    χ::T2 = 0.7 | (0.4, 0.9) | "ratio of leaf internal to ambient CO2" | "" | ""
    ref_ambient_CO2::T3 = 380.0 | (300.0, 500.0) | "ambient CO2 at which the CO2 effect is one" | "ppm" | ""
    Γ_star_25::T4 = 42.75 | (-Inf, Inf) | "CO2 compensation point at 25 °C" | "ppm" | ""
    ΔH_Γ_star::T5 = 37830.0 | (-Inf, Inf) | "activation energy of the CO2 compensation point" | "J mol-1" | ""
    gas_constant::T6 = 8.314 | (-Inf, Inf) | "universal gas constant" | "J mol-1 K-1" | ""
end
#! format: on

"""
    lightLimitedCO2(ci, Γ_star, t_two, t_three)

CO2 dependence m = (ci - Γ*) / (ci + 2Γ*) of the light limited rate of C3
photosynthesis and its sensitivity s = d ln m / d ln χ to the ratio of leaf internal
to ambient CO2. Both are zero when ci is at or below Γ*.
"""
function lightLimitedCO2(ci, Γ_star, t_two, t_three)
    m = at_least_zero(ci - Γ_star) / (ci + t_two * Γ_star)
    s = ci > Γ_star ? t_three * Γ_star * ci / ((ci - Γ_star) * (ci + t_two * Γ_star)) : zero(ci)
    return m, s
end

function define(params::gppVPD_Farquhar1980, forcing, land, helpers)
    @unpack_gppVPD_Farquhar1980 params

    ## reference temperature of Γ_star_25 and 0 °C, in K
    T_25 = oftype(Γ_star_25, 298.15)
    T_0 = oftype(Γ_star_25, 273.15)

    @pack_nt (T_25, T_0) ⇒ land.gppVPD
    return land
end

function compute(params::gppVPD_Farquhar1980, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppVPD_Farquhar1980 params
    @unpack_nt (f_airT_day, f_VPD_day) ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        ambient_CO2 ⇐ land.states
        (t_two, t_three) ⇐ land.constants
        (T_25, T_0) ⇐ land.gppVPD
    end

    ## CO2 compensation point at the air temperature
    T_air = f_airT_day + T_0
    Γ_star = Γ_star_25 * exp(ΔH_Γ_star * (T_air - T_25) / (T_25 * gas_constant * T_air))

    ## CO2 effect of light limited photosynthesis, normalized by its value at
    # ref_ambient_CO2 with the same Γ_star. The temperature dependence of Γ_star then
    # changes only the CO2 sensitivity and does not reduce GPP by itself.
    m_CO2, s_CO2 = lightLimitedCO2(χ * ambient_CO2, Γ_star, t_two, t_three)
    m_ref, s_ref = lightLimitedCO2(χ * ref_ambient_CO2, Γ_star, t_two, t_three)
    gpp_f_co2 = safe_divide(m_CO2, m_ref)

    ## VPD stress of Maekelae (2008) with κ at ref_ambient_CO2. Closing stomata
    # lowers χ, and the loss of photosynthesis for a given drop of χ scales with s,
    # which falls at higher CO2.
    gpp_f_vpd = exp(-κ * f_VPD_day * safe_divide(s_CO2, s_ref)) * gpp_f_co2

    ## pack land variables
    @pack_nt (gpp_f_co2, gpp_f_vpd) ⇒ land.diagnostics
    return land
end

purpose(::Type{gppVPD_Farquhar1980}) = "VPD stress on GPP potential based on Maekelae (2008), with the CO₂ effect of light limited C3 photosynthesis of Farquhar et al. (1980)."

@doc """

$(getModelDocString(gppVPD_Farquhar1980))

---

# Extended help

The CO2 effect is m(Ca) / m(ref_ambient_CO2), where m = (Ci - Γ*) / (Ci + 2Γ*) is the
CO2 dependence of the light limited rate of C3 photosynthesis and Ci = χ Ca. The CO2
effect is one at ref_ambient_CO2, stays positive for Ci above Γ*, and saturates at
high CO2. Its sensitivity, d ln m / d ln Ca, is about 0.4 at 400 ppm and 25 °C.

The VPD stress is exp(-κ VPD s(Ca) / s(ref_ambient_CO2)), the stress of
gppVPD_Maekelae2008 scaled by s = d ln m / d ln χ = 3Γ* Ci / ((Ci - Γ*)(Ci + 2Γ*)).
VPD closes stomata and lowers χ, and the relative loss of photosynthesis for a given
drop of χ is s, which falls as CO2 rises. The scale is one at ref_ambient_CO2, is
close to ref_ambient_CO2 / Ca when Γ* is small, and has no free parameter. It
replaces the calibrated exponent c_κ of gppVPD_PRELES, which is not identifiable from
the narrow CO2 range of the calibration period and extrapolates badly to the CO2 of
1700 or 1901.

Γ* follows the air temperature with the Arrhenius function of Bernacchi et al.
(2001). The reference uses the same Γ*, so both factors are one at ref_ambient_CO2
at every temperature, and a higher temperature only makes GPP more sensitive to CO2.

χ and ref_ambient_CO2 are not meant to be calibrated, since both effects are close
to one over the calibration period. WUE_Farquhar1980 uses the same fixed χ, under
which WUE grows in proportion to Ca, and its ref_ambient_CO2 should have the same
value.

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
 - 1.1 on 05.11.2026 [skoirala | @dr-ko]: the CO2 dependence of the VPD stress is
   s(Ca) / s(ref_ambient_CO2) of the light limited rate instead of the calibrated
   power (Ca / ref_ambient_CO2)^c_κ.

*Created by*
 - skoirala | @dr-ko
"""
gppVPD_Farquhar1980
