export gpp_JSBACH

*#! format: off*

@bounds @describe @units @timescale @with_kw struct gpp_JSBACH{
    T1, T2, T3, T4, T5, T6,
    T7, T8, T9, T10, T11, T12
} <: gpp

    # Photosynthesis parameters

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

end

*#! format: on*


function compute(params::gpp_JSBACH, forcing, land, helpers)

    @unpack_gpp_JSBACH params

    @unpack_nt begin

        f_airT ⇐ forcing
        f_psurf ⇐ forcing
        f_rg ⇐ forcing

        ambient_CO2 ⇐ land.states
        APAR ⇐ land.states
        LAI ⇐ land.states

        canopy_cond_cl_limited ⇐ land.diagnostics

        (
            const_tmelt,
            mol_to_gC_day,
            const_rgas,
            J_to_MJ,
            MJ_to_J,
            d_to_s,
            o_one
        ) ⇐ land.constants

    end


    # ============================================================
    # Type-consistent numerical constants
    # ============================================================

    T_zero = oftype(f_airT, 0.0)
    T_one  = oftype(f_airT, 1.0)
    T_two  = oftype(f_airT, 2.0)
    T_four = oftype(f_airT, 4.0)

    temp_ref_C =
        oftype(f_airT, 25.0)

    gamma_coeff =
        oftype(f_airT, 1.7e-6)

    jmax_floor =
        oftype(f_airT, 1e-12)

    high_temp_coeff =
        oftype(f_airT, 1.3)

    high_temp_threshold =
        oftype(f_airT, 55.0)

    dark_inhib_coeff =
        oftype(f_airT, 2.0e5)

    diffusivity_ratio =
        oftype(f_airT, 1.6)

    # ============================================================
    # 1. Temperature
    # ============================================================

    # 25°C in Kelvin
    T1 =
        temp_ref_C + const_tmelt

    # Air temperature in Kelvin
    ta =
        f_airT + const_tmelt

    # Air temperature in Celsius
    tc =
        f_airT

    # Relative temperature to 25°C
    T0 =
        ta - T1


    # ============================================================
    # 2. CO2
    # ============================================================

    # Convert ambient CO2 using existing model conversion
    co2_air_mol =
        ambient_CO2 * J_to_MJ


    # ============================================================
    # 3. PAR
    # ============================================================

    # Incoming radiation:
    # MJ m-2 day-1 -> W m-2 -> mol photons m-2 s-1
    par_down_mol =
        f_rg *
        MJ_to_J /
        d_to_s /
        epar


    # ============================================================
    # 4. Temperature-dependent Michaelis-Menten constants
    # ============================================================

    kc =
        KC0 *
        exp(
            EC *
            T0 /
            const_rgas /
            T1 /
            ta
        )

    ko =
        KO0 *
        exp(
            EO *
            T0 /
            const_rgas /
            T1 /
            ta
        )


    # ============================================================
    # 5. Compensation point (Gamma*)
    # ============================================================

    gam =
        max(
            gamma_coeff * tc,
            zero(tc)
        )


    # ============================================================
    # 6. Temperature-dependent maximum rates
    # ============================================================

    vcmax =
        v_cmax_25 *
        exp(
            EV *
            T0 /
            const_rgas /
            T1 /
            ta
        )

    jmax =
        max(
            j_max_25 *
            (tc / temp_ref_C),
            jmax_floor
        )


    # ============================================================
    # 7. Light-limited electron transport
    # ============================================================

    j1 =
        if jmax > jmax_floor

            alpha *
            APAR *
            jmax /
            sqrt(
                jmax^2 +
                (
                    alpha *
                    APAR
                )^2
            )

        else

            zero(jmax)

        end


    # ============================================================
    # 8. High-temperature inhibition
    # ============================================================

    hit_inhib =
        T_one /
        (
            T_one +
            exp(
                high_temp_coeff *
                (
                    tc -
                    high_temp_threshold
                )
            )
        )


    # ============================================================
    # 9. Dark respiration
    # ============================================================

    dark_inhib =
        oftype(f_airT, 0.5) +
        oftype(f_airT, 0.5) *
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
            ER *
            T0 /
            const_rgas /
            T1 /
            ta
        ) *
        hit_inhib *
        dark_inhib


    # ============================================================
    # 10. Stomatal conductance term
    # ============================================================

    g0 =
        canopy_cond_cl_limited /
        (
            diffusivity_ratio *
            const_rgas *
            ta
        ) *
        f_psurf

    g0 =
        isfinite(g0) ?
        g0 :
        zero(g0)


    # ============================================================
    # 11. Electron transport limitation (JE)
    # ============================================================

    j_over_four =
        j1 / T_four

    B_e =
        dark_resp +
        j_over_four +
        g0 *
        (
            co2_air_mol +
            T_two * gam
        )

    C_e =
        j_over_four *
        g0 *
        (
            co2_air_mol -
            gam
        ) +
        j_over_four *
        dark_resp

    discriminant_e =
        max(
            B_e^2 / T_four -
            C_e,
            zero(B_e)
        )

    je_stress =
        if j1 > jmax_floor

            B_e / T_two -
            sqrt(discriminant_e)

        else

            zero(j1)

        end


    # ============================================================
    # 12. Rubisco-limited photosynthesis (JC)
    # ============================================================

    k2 =
        kc *
        (
            T_one +
            OX / ko
        )

    B_c =
        dark_resp +
        vcmax +
        g0 *
        (
            co2_air_mol +
            k2
        )

    C_c =
        vcmax *
        g0 *
        (
            co2_air_mol -
            gam
        ) +
        vcmax *
        dark_resp

    discriminant_c =
        max(
            B_c^2 / T_four -
            C_c,
            zero(B_c)
        )

    jc_stress =
        B_c / T_two -
        sqrt(discriminant_c)


    # ============================================================
    # 13. Gross photosynthesis
    # ============================================================

    gpp_mol =
        min(
            je_stress,
            jc_stress
        ) *
        hit_inhib

    gpp_mol =
        isfinite(gpp_mol) ?
        max(
            gpp_mol,
            zero(gpp_mol)
        ) :
        zero(gpp_mol)


    # ============================================================
    # 14. Scale by LAI to ground area
    # ============================================================

    gpp_ground_daily =
        gpp_mol *
        LAI *
        mol_to_gC_day


    # ============================================================
    # 15. Final GPP
    # ============================================================

    gpp =
        isfinite(gpp_ground_daily) ?
        max(
            gpp_ground_daily,
            zero(gpp_ground_daily)
        ) :
        zero(gpp_ground_daily)


    # ============================================================
    # Pack diagnostics
    # ============================================================

    @pack_nt begin
        gpp ⇒ land.fluxes

        vcmax ⇒ land.diagnostics

        jmax ⇒ land.diagnostics

        je_stress ⇒ land.diagnostics

        jc_stress ⇒ land.diagnostics
    end

    return land
end


purpose(::Type{gpp_JSBACH}) =
    "Calculate GPP based on the JSBACH C3 photosynthesis scheme with correct temperature scaling (K/C)."


@doc """

$(getModelDocString(gpp_JSBACH))

---

# Extended help

*References*

- JSBACH 3.2 documentation (mo_assimi.f90)

- Farquhar, G. D., von Caemmerer, S., & Berry, J. A. (1980)

*Versions*

- 1.0 on 03.03.2026 [Ported & structured for framework]

*Created by*

- skoirala

"""

gpp_JSBACH