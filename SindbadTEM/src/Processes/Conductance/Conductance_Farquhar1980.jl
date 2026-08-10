export Conductance_Farquhar1980

@bounds @describe @units @timescale @with_kw struct Conductance_Farquhar1980{T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17} <: Conductance
    # Maximum rates at 25°C (C3 typical values)
    v_cmax_25::T1 = 60.0 * 1e-6     | (20.0* 1e-6, 120.0* 1e-6) | "Maximum carboxylation rate at 25C" | "μmol CO₂ m⁻² s⁻¹" | ""
    j_max_25::T2  = 114.0 * 1e-6   | (40.0* 1e-6, 220.0* 1e-6) | "Maximum electron transport rate at 25C" | "μmol CO₂ m⁻² s⁻¹" | ""    
    alpha::T3     = 0.28     | (0.01, 0.5)   | "Quantum yield efficiency" | "mol/mol" | ""
    frdc3::T4     = 0.015    | (0.001, 0.1)  | "Dark respiration fraction" | "" | ""
    epar::T5      = 2.1739e5 | (1e5, 3e5)    | "Energy content of PAR" | "J mol⁻¹" | ""

    # Activation Energies
    EC::T6  = 59356.0 | (1e4, 1e5) | "Activation energy for Michaelis-Menten CO2" | "J/mol" | ""
    EO::T7  = 35948.0 | (1e4, 1e5) | "Activation energy for Michaelis-Menten O2"  | "J/mol" | ""
    EV::T8  = 58520.0 | (1e4, 1e5) | "Activation energy for maximum carboxylation rate" | "J/mol" | ""
    ER::T9  = 45000.0 | (1e4, 1e5) | "Activation energy for dark respiration" | "J/mol" | ""

    # Michaelis-Menten constants
    KC0::T10 = 4.6e-4 | (1e-5, 1e-3) | "Michaelis-Menten constant for CO2 at 25C" | "mol/mol" | ""
    KO0::T11 = 3.3e-1 | (1e-2, 1e-0) | "Michaelis-Menten constant for O2 at 25C"  | "mol/mol" | ""
    OX::T12  = 0.21   | (0.1, 0.3)   | "Oxygen concentration" | "mol/mol" | ""

    diffusivity_ratio::T13 = 1.6 | (1.0, 2.0) | "H2O/CO2 diffusivity ratio" | "" | ""
    fci1c3::T14 = 0.7 | (0.1, 0.9) | "Ci/Ca ratio (C3)" | "" | ""
    w_soil_crit_fract::T15 = 0.5   | (0.0, 1.0) | "Critical soil moisture fraction" | "" | ""
    w_soil_wilt_fract::T16 = 0.1   | (0.0, 1.0) | "Wilting point soil moisture fraction" | "" | ""
    eps_min::T17           = 1e-20 | (0.0, 1e-5) | "Minimum conductance if air saturated" | "mol m-2 s-1" | ""


end


function compute(params::Conductance_Farquhar1980, forcing, land, helpers)

    @unpack_Conductance_Farquhar1980 params

    # === Unpack inputs ===
    @unpack_nt begin
        (f_airT, f_psurf,f_rg,f_VPD) ⇐ forcing
        (MJ_to_J, d_to_s) ⇐ land.constants
        (ambient_CO2, LAI, APAR, PAW, w_awc_root_zone) ⇐ land.states
        w_awc ⇐ land.properties     # ppm
    end

    ## ============================================================
    ## 1) WATER Unlimited conditions
    ## ============================================================


    t_air = f_airT + 273.15  # °C → K
     
    # === Constants ===
    tmelt = 273.15
    R = 8.31446
    minOfMaxCarboxrate = 1e-12
    minStomaConductance = 1e-20
    par_down_w = f_rg * MJ_to_J / d_to_s   # MJ/m²/d → W/m²

    # === Temperature terms ===
    T1 = 25.0 + tmelt
    T0 = t_air - T1
    TC = t_air - tmelt
    t_factor = T0 / (T1 * t_air)

    # === CO2 ===
    co2_air_mol = ambient_CO2 * 1e-6   # ppm → mol/mol
    ci = fci1c3 * co2_air_mol

    # === Michaelis-Menten constants ===
    kc = KC0 * exp(EC / R * t_factor)
    ko = KO0 * exp(EO / R * t_factor)

    # === Compensation point ===
    gam = max(1.7e-6 * TC, 0.0)

    # === Vcmax & Jmax ===
    vcmax = v_cmax_25 * exp(EV / R * t_factor)
    jmax  = max(j_max_25 * TC / 25.0, minOfMaxCarboxrate)

    # === Electron transport rate ===
    j_light = if jmax > minOfMaxCarboxrate
        alpha * APAR * jmax /
        sqrt(jmax^2 + (alpha * APAR)^2)
    else
        0.0
    end

    je = j_light * (ci - gam) / (4.0 * (ci + 2.0 * gam))
    jc = vcmax * (ci - gam) / (ci + kc * (1.0 + OX / ko))

    # === High temperature inhibition ===
    hit_inhib = 1.0 / (1.0 + exp(1.3 * (TC - 55.0)))
    gass = min(je, jc) * hit_inhib

    # === Dark respiration ===
    par_down_mol = par_down_w / epar
    dark_inhib = 0.5 + 0.5 * exp(-2e5 * max(par_down_mol, 0.0))

    dark_resp = frdc3 * v_cmax_25 *
                exp(ER / R * t_factor) *
                hit_inhib * dark_inhib

    # === Stomatal conductance ===
    denom = max(co2_air_mol - ci, 1e-12)


    leaf_cond_raw =
        diffusivity_ratio *
        (gass - dark_resp) /
        denom *
        (R * t_air / f_psurf)


    leaf_cond = max(leaf_cond_raw, minStomaConductance)

    leaf_cond = isfinite(leaf_cond) ? leaf_cond : minStomaConductance

    canopy_cond_unlimited = leaf_cond * LAI

    
    # ## ============================================================
    # ## 1) WATER STRESS FACTOR  (JSBACH equivalent)
    # ## ============================================================

    # w_crit = wtr_rootzone_avail_max .* w_soil_crit_fract
    # w_wilt = wtr_rootzone_avail_max .* w_soil_wilt_fract

    # denom = w_crit .- w_wilt
    
    # water_stress = ifelse.(
    #     denom .> 0,
    #     clamp.(
    #         (wtr_rootzone_avail .- w_wilt) ./ denom,
    #         0,
    #         1
    #     ),
    #     zero(eltype(denom))
    # )
    #water_stress = sum(PAW) / sum(w_awc_root_zone)
    water_stress = if isfinite(sum(PAW)) &&
                   isfinite(sum(w_awc_root_zone)) &&
                   sum(w_awc_root_zone) > 1e-12
    sum(PAW) / sum(w_awc_root_zone)
    else
        1.0
    end

    # ## 2) HUMIDITY & SATURATION LOGIC
    # ## ============================================================

    # ---- Constants ----
    EPSILON_V = 0.622  # Ratio of molecular weights (Mw/Md)
    
    # ---- Temperatures ----
    TC = t_air - 273.15  # Celsius
    # Note: t_air is Kelvin

    # ---- Saturation Vapor Pressure (esat) [Pa] ----
    # Standard Tetens: 610.78 * exp( (17.2694 * TC) / (TC + 237.3) )
    # This is mathematically the same as JSBACH's Kelvin version
    esat = 610.78 * exp(17.2694 * TC / (TC + 237.3))

    # ---- Actual Vapor Pressure (e_act) [Pa] ----
    # f_VPD is kPa, so multiply by 1000 to get Pa
    vpd_pa = f_VPD * 1000.0
    e_act  = max(esat - vpd_pa, 0.0)

    # ---- Specific Humidity (q_air) [kg/kg] ----
    denom_act = f_psurf - (1.0 - EPSILON_V) * e_act
    q_air     = (EPSILON_V * e_act) / max(denom_act, 1e-12)

    # ---- Saturation Specific Humidity (qsat) [kg/kg] ----
    denom_q = f_psurf - (1.0 - EPSILON_V) * esat
    qsat    = (EPSILON_V * esat) / max(denom_q, 1e-12)

    # ---- Saturation Check ----
    # If VPD > 0, q_air will always be less than qsat.
    air_is_saturated = q_air >= qsat

    # ## ============================================================
    # ## 4) STRESSED CANOPY CONDUCTANCE
    # ## ============================================================

    canopy_cond_limited = if air_is_saturated
        eps_min
    else
        # Standard JSBACH: scale the unlimited conductance by soil water stress
        canopy_cond_unlimited * water_stress
    end

    # Calculate the layered scaling ratio for the final diagnostic
    ratio_lim_over_unlim = canopy_cond_unlimited > 1e-20 ? 
                           (canopy_cond_limited / canopy_cond_unlimited) : 1.0
                           
    canopy_cond_cl_limited = leaf_cond * ratio_lim_over_unlim
    


    # === Pack diagnostics ===
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

"""
Conductance_Farquhar1980
