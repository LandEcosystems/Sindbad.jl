export WUE_Farquhar1980

#! format: off
@bounds @describe @units @timescale @with_kw struct WUE_Farquhar1980{T1,T2,T3} <: WUE
    WUE_base::T1 = 9.2 | (2.0, 20.0) | "WUE at zero VPD and the reference ambient CO2" | "gC/mmH2O" | ""
    κ::T2 = 0.4 | (0.06, 0.7) | "sensitivity of WUE to VPD" | "kPa-1" | ""
    ref_ambient_CO2::T3 = 380.0 | (-Inf, Inf) | "ambient CO2 at which the CO2 effect is one" | "ppm" | ""
end
#! format: on

function compute(params::WUE_Farquhar1980, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_WUE_Farquhar1980 params
    @unpack_nt f_VPD_day ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        ambient_CO2 ⇐ land.states
    end

    ## calculate variables
    WUENoCO2 = WUE_base * exp(κ * -(f_VPD_day))
    # WUE is proportional to ambient CO2 at a fixed ratio of leaf internal to
    # ambient CO2
    WUE = WUENoCO2 * ambient_CO2 / ref_ambient_CO2

    ## pack land variables
    @pack_nt (WUENoCO2, WUE) ⇒ land.diagnostics
    return land
end

purpose(::Type{WUE_Farquhar1980}) = "Calculates WUE as a function of WUE at zero VPD, daily mean VPD, and a CO₂ effect proportional to ambient CO₂."

@doc """

$(getModelDocString(WUE_Farquhar1980))

---

# Extended help

The CO2 effect is ambient_CO2 / ref_ambient_CO2. With a fixed ratio χ of leaf
internal to ambient CO2, assimilation is g_s Ca (1 - χ) and transpiration is
1.6 g_s VPD, so WUE grows in proportion to Ca. This is the assumption of
gppVPD_Farquhar1980, whose ref_ambient_CO2 should have the same value. The effect has
no free parameter. ref_ambient_CO2 is not meant to be calibrated, since only its
ratio to WUE_base is identifiable.

The VPD effect exp(-κ VPD) is empirical, with VPD in kPa and κ in kPa-1, so WUE_base
is WUE at zero VPD. At a fixed χ, theory gives WUE proportional to 1 / VPD, and with
the optimal χ of Medlyn et al. (2011) it gives Ca / (1.6 (g1 sqrt(VPD) + VPD)). The
exponential stays finite at low VPD and decays more weakly, and κ is calibrated
against transpiration and evapotranspiration. CO2 and VPD act on WUE independently,
as in both theoretical forms.

With gpp_coupled and transpiration_coupled, demand limited transpiration is
gpp / WUE and varies with VPD as exp(-(κ_gpp - κ) VPD), where κ_gpp is the VPD
sensitivity of GPP. Transpiration then rises with VPD only when κ is larger than
κ_gpp. With gppVPD_Farquhar1980, κ_gpp is scaled down at higher CO2.

WUE is gpp over transpiration, in gC per mm of water, so it does not depend on the
model time step.

*References*
 - Farquhar, G. D., von Caemmerer, S., & Berry, J. A. (1980). A biochemical model
   of photosynthetic CO2 assimilation in leaves of C3 species. Planta, 149, 78-90.
 - Medlyn, B. E., Duursma, R. A., Eamus, D., et al. (2011). Reconciling the optimal
   and empirical approaches to modelling stomatal conductance. Global Change
   Biology, 17, 2134-2144.

*Versions*
 - 1.0 on 03.11.2026 [skoirala | @dr-ko]
 - 1.1 on 05.11.2026 [skoirala | @dr-ko]: renamed from WUE_expVPDDayCo2Linear, and
   WUE_one_hpa renamed to WUE_base, since exp(-κ VPD) is one at zero VPD.

*Created by*
 - skoirala | @dr-ko
"""
WUE_Farquhar1980
