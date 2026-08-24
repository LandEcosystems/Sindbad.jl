export Conductance_Farquhar1980

@bounds @describe @units @timescale @with_kw struct Conductance_Farquhar1980{
    T1, T2, T3, T4, T5, T6, T7, T8, T9,
    T10, T11, T12, T13, T14, T15, T16, T17
} <: stomatalConductance

    # Maximum rates at 25°C (C3 typical values)

    v_cmax_25::T1 = 60.0 * 1e-6 |
        (20.0 * 1e-6, 120.0 * 1e-6) |
        "Maximum carboxylation rate at 25C" |
        "μmol CO₂ m⁻² s⁻¹" | ""

    j_max_25::T2 = 114.0 * 1e-6 |
        (40.0 * 1e-6, 220.0 * 1e-6) |
        "Maximum electron transport rate at 25C" |
        "μmol CO₂ m⁻² s⁻¹" | ""

    alpha::T3 = 0.28 |
        (0.01, 0.5) |
        "Quantum yield efficiency" |
        "mol/mol" | ""

    frdc3::T4 = 0.015 |
        (0.001, 0.1) |
        "Dark respiration fraction" |
        "" | ""

    epar::T5 = 2.1739e5 |
        (1e5, 3e5) |
        "Energy content of PAR" |
        "J mol⁻¹" | ""

    # Activation Energies

    EC::T6 = 59356.0 |
        (1e4, 1e5) |
        "Activation energy for Michaelis-Menten CO2" |
        "J/mol" | ""

    EO::T7 = 35948.0 |
        (1e4, 1e5) |
        "Activation energy for Michaelis-Menten O2" |
        "J/mol" | ""

    EV::T8 = 58520.0 |
        (1e4, 1e5) |
        "Activation energy for maximum carboxylation rate" |
        "J/mol" | ""

    ER::T9 = 45000.0 |
        (1e4, 1e5) |
        "Activation energy for dark respiration" |
        "J/mol" | ""

    # Michaelis-Menten constants

    KC0::T10 = 4.6e-4 |
        (1e-5, 1e-3) |
        "Michaelis-Menten constant for CO2 at 25C" |
        "mol/mol" | ""

    KO0::T11 = 3.3e-1 |
        (1e-2, 1e-0) |
        "Michaelis-Menten constant for O2 at 25C" |
        "mol/mol" | ""

    OX::T12 = 0.21 |
        (0.1, 0.3) |
        "Oxygen concentration" |
        "mol/mol" | ""

    diffusivity_ratio::T13 = 1.6 |
        (1.0, 2.0) |
        "H2O/CO2 diffusivity ratio" |
        "" | ""

    fci1c3::T14 = 0.7 |
        (0.1, 0.9) |
        "Ci/Ca ratio (C3)" |
        "" | ""

    w_soil_crit_fract::T15 = 0.5 |
        (0.0, 1.0) |
        "Critical soil moisture fraction" |
        "" | ""

    w_soil_wilt_fract::T16 = 0.1 |
        (0.0, 1.0) |
        "Wilting point soil moisture fraction" |
        "" | ""

    eps_min::T17 = 1e-20 |
        (0.0, 1e-5) |
        "Minimum conductance if air saturated" |
        "mol m-2 s-1" | ""

end


function compute(params::Conductance_Farquhar1980, forcing, land, helpers)

    @unpack_Conductance_Farquhar1980 params

    # ============================================================
    # Unpack inputs
    # ============================================================

    @unpack_nt begin
        (f_airT, f_psurf, f_rg, f_VPD) ⇐ forcing

        (MJ_to_J, d_to_s, const_tmelt, epsilon, o_one) ⇐ land.constants

        (ambient_CO2, LAI, APAR, PAW, w_awc_root_zone) ⇐ land.states
    end

    # ============================================================
    # Type-consistent numerical constants
    # ============================================================

    T_zero = oftype(f_airT, 0.0)
    T_one  = oftype(f_airT, 1.0)
    T_two  = oftype(f_airT, 2.0)
    T_four = oftype(f_airT, 4.0)

    R = oftype(f_airT, 8.31446)

    minOfMaxCarboxrate =
        oftype(f_airT, 1e-12)

    minStomaConductance =
        oftype(f_airT, 1e-20)

    # Reference temperature
    temp_ref_C =
        oftype(f_airT, 25.0)

    # Compensation point coefficient
    gamma_coeff =
        oftype(f_airT, 1.7e-6)

    # High-temperature inhibition
    high_temp_coeff =
        oftype(f_airT, 1.3)

    high_temp_threshold =
        oftype(f_airT, 55.0)

    # Dark respiration light inhibition
    dark_inhib_coeff =
        oftype(f_airT, 2e5)

    half =
        oftype(f_airT, 0.5)

    # Saturation vapor pressure constants
    esat_ref =
        oftype(f_airT, 610.78)

    esat_slope =
        oftype(f_airT, 17.2694)

    esat_offset =
        oftype(f_airT, 237.3)

    # CO2 ppm -> mol/mol
    co2_scale =
        oftype(ambient_CO2, 1e-6)

    # VPD kPa -> Pa
    vpd_scale =
        oftype(f_VPD, 1000.0)

    # Numerical pressure floor
    pressure_floor =
        oftype(f_psurf, 1e-12)

    # ============================================================
    # 1) WATER UNLIMITED CONDITIONS
    # ============================================================

    # Air temperature: °C -> K
    t_air =
        f_airT + const_tmelt

    # ============================================================
    # Temperature terms
    # ============================================================

    T1_ref =
        temp_ref_C + const_tmelt

    T0 =
        t_air - T1_ref

    TC =
        t_air - const_tmelt

    t_factor =
        T0 / (T1_ref * t_air)

    # ============================================================
    # CO2
    # ============================================================

    co2_air_mol =
        ambient_CO2 * co2_scale

    ci =
        fci1c3 * co2_air_mol

    # ============================================================
    # Michaelis-Menten constants
    # ============================================================

    kc =
        KC0 *
        exp(
            (EC / R) * t_factor
        )

    ko =
        KO0 *
        exp(
            (EO / R) * t_factor
        )

    # ============================================================
    # Compensation point
    # ============================================================

    gam =
        max(
            gamma_coeff * TC,
            zero(TC)
        )

    # ============================================================
    # Vcmax & Jmax
    # ============================================================

    vcmax =
        v_cmax_25 *
        exp(
            (EV / R) * t_factor
        )

    jmax =
        max(
            j_max_25 * TC / temp_ref_C,
            minOfMaxCarboxrate
        )

    # ============================================================
    # Electron transport rate
    # ============================================================

    j_light =
        if jmax > minOfMaxCarboxrate

            alpha * APAR * jmax /
            sqrt(
                jmax^2 +
                (alpha * APAR)^2
            )

        else
            zero(jmax)
        end

    je =
        j_light * (ci - gam) /
        (
            T_four *
            (
                ci +
                T_two * gam
            )
        )

    jc =
        vcmax * (ci - gam) /
        (
            ci +
            kc *
            (
                T_one +
                OX / ko
            )
        )

    # ============================================================
    # High-temperature inhibition
    # ============================================================

    hit_inhib =
        T_one /
        (
            T_one +
            exp(
                high_temp_coeff *
                (
                    TC -
                    high_temp_threshold
                )
            )
        )

    gass =
        min(je, jc) *
        hit_inhib

    # ============================================================
    # Dark respiration
    # ============================================================

    par_down_w =
        f_rg *
        MJ_to_J /
        d_to_s

    par_down_mol =
        par_down_w /
        epar

    dark_inhib =
        half +
        half *
        exp(
            -dark_inhib_coeff *
            max(
                par_down_mol,
                zero(par_down_mol)
            )
        )

    dark_resp =
        frdc3 *
        v_cmax_25 *
        exp(
            (ER / R) *
            t_factor
        ) *
        hit_inhib *
        dark_inhib

    # ============================================================
    # Stomatal conductance
    # ============================================================

    denom =
        max(
            co2_air_mol - ci,
            oftype(co2_air_mol, 1e-12)
        )

    leaf_cond_raw =
        diffusivity_ratio *
        (gass - dark_resp) /
        denom *
        (
            R *
            t_air /
            f_psurf
        )

    leaf_cond =
        max(
            leaf_cond_raw,
            minStomaConductance
        )

    leaf_cond =
        isfinite(leaf_cond) ?
        leaf_cond :
        minStomaConductance

    canopy_cond_unlimited =
        leaf_cond *
        LAI

    # ============================================================
    # 2) WATER STRESS FACTOR
    # ============================================================

    paw_sum =
        sum(PAW)

    awc_sum =
        sum(w_awc_root_zone)

    water_stress =
        if isfinite(paw_sum) &&
           isfinite(awc_sum) &&
           awc_sum > oftype(awc_sum, 1e-12)

            paw_sum / awc_sum

        else
            o_one
        end

    # ============================================================
    # 3) HUMIDITY & SATURATION LOGIC
    # ============================================================

    # Saturation vapor pressure [Pa]
    esat =
        esat_ref *
        exp(
            esat_slope *
            TC /
            (
                TC +
                esat_offset
            )
        )

    # Actual vapor pressure [Pa]
    # f_VPD is provided in kPa
    vpd_pa =
        f_VPD *
        vpd_scale

    e_act =
        max(
            esat - vpd_pa,
            zero(esat)
        )

    # ============================================================
    # Specific humidity
    # ============================================================

    denom_act =
        f_psurf -
        (
            o_one -
            epsilon
        ) *
        e_act

    q_air =
        (
            epsilon *
            e_act
        ) /
        max(
            denom_act,
            pressure_floor
        )

    denom_q =
        f_psurf -
        (
            o_one -
            epsilon
        ) *
        esat

    qsat =
        (
            epsilon *
            esat
        ) /
        max(
            denom_q,
            pressure_floor
        )

    # ============================================================
    # Saturation check
    # ============================================================

    air_is_saturated =
        q_air >= qsat

    # ============================================================
    # 4) STRESSED CANOPY CONDUCTANCE
    # ============================================================

    canopy_cond_limited =
        if air_is_saturated

            eps_min

        else

            canopy_cond_unlimited *
            water_stress

        end

    # ============================================================
    # Layered scaling ratio
    # ============================================================

    canopy_cond_floor =
        oftype(
            canopy_cond_unlimited,
            1e-20
        )

    ratio_lim_over_unlim =
        canopy_cond_unlimited >
        canopy_cond_floor ?

        (
            canopy_cond_limited /
            canopy_cond_unlimited
        ) :

        o_one

    canopy_cond_cl_limited =
        leaf_cond *
        ratio_lim_over_unlim

    # ============================================================
    # Pack diagnostics
    # ============================================================

    @pack_nt canopy_cond_unlimited ⇒ land.diagnostics
    @pack_nt leaf_cond ⇒ land.diagnostics
    @pack_nt canopy_cond_limited ⇒ land.diagnostics
    @pack_nt canopy_cond_cl_limited ⇒ land.diagnostics
    @pack_nt water_stress ⇒ land.diagnostics

    return land
end


purpose(::Type{Conductance_Farquhar1980}) =
    "Stressed canopy conductance following JSBACH C3 (Knorr 1997)."


@doc """

$(getModelDocString(Conductance_Farquhar1980))

---

# Extended help

*References*

*Versions*

 - 1.0 on 03.03.2026 [skoirala]

*Created by*

 - skoirala

*Notes*

"""

Conductance_Farquhar1980