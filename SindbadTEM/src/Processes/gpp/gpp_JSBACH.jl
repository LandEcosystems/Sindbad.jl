export gpp_JSBACH

#! format: off
@bounds @describe @units @timescale @with_kw struct gpp_JSBACH{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12} <: gpp
    # Photosynthesis parameters
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
end
#! format: on

function compute(params::gpp_JSBACH, forcing, land, helpers)
    @unpack_gpp_JSBACH params
    @unpack_nt begin
        f_airT ⇐ forcing        # Air temperature in °C
        f_psurf ⇐ forcing       # Surface pressure (Pa)
        f_rg ⇐ forcing          # Incoming radiation (MJ/m²/d)
        ambient_CO2 ⇐ land.states
        APAR ⇐ land.states
        LAI ⇐ land.states
        canopy_cond_cl_limited ⇐ land.diagnostics
        (const_tmelt,mol_to_gC_day,const_rgas,J_to_MJ,MJ_to_J,d_to_s) ⇐ land.constants
    end


    # ---- Physical constants ----
    T1 = 25.0 + const_tmelt           # 25°C in Kelvin
    ta = f_airT + const_tmelt         # Air temperature in Kelvin
    tc = f_airT                       # Air temperature in Celsius
    T0 = ta - T1                      # Relative temperature to 25°C in Kelvin
                
    # ---- CO2 in mol/mol ----
    co2_air_mol = ambient_CO2 * J_to_MJ

    # ---- PAR in mol photons m⁻² s⁻¹ ----
    par_down_mol = f_rg * MJ_to_J / d_to_s / epar

    # ---- Temperature-dependent Michaelis-Menten constants ----
    kc = KC0 * exp(EC * T0 / const_rgas / T1 / ta)
    ko = KO0 * exp(EO * T0 / const_rgas / T1 / ta)

    # ---- Compensation point (Gamma*) ----
    gam = max(1.7e-6 * tc, 0.0)

    # ---- Temperature-dependent maximum rates ----
    vcmax = v_cmax_25 * exp(EV * T0 / const_rgas / T1 / ta)
    jmax  = max(j_max_25 * (tc / 25.0), 1e-12)

    # ---- Light-limited electron transport ----
    j1 = if jmax > 1e-12
        alpha * APAR * jmax / sqrt(jmax^2 + (alpha * APAR)^2)
    else
        0.0
    end

    # ---- High temperature inhibition ----
    hit_inhib  = 1.0 / (1.0 + exp(1.3 * (tc - 55.0)))

    # ---- Dark respiration ----
    dark_inhib = 0.5 + 0.5 * exp(-2.0e5 * max(par_down_mol, 0.0))
    dark_resp  = frdc3 * v_cmax_25 * exp(ER * T0 / const_rgas / T1 / ta) * hit_inhib * dark_inhib

    # ---- Stomatal conductance term ----
    g0 = canopy_cond_cl_limited / (1.6 * const_rgas * ta) * f_psurf
    g0 = isfinite(g0) ? g0 : 0.0

    # ---- Electron transport limitation (JE) ----
    B_e = dark_resp + j1 / 4.0 + g0 * (co2_air_mol + 2.0 * gam)
    C_e = (j1 / 4.0) * g0 * (co2_air_mol - gam) + (j1 / 4.0) * dark_resp
    je_stress = j1 > 1e-12 ? B_e / 2.0 - sqrt(max(B_e^2 / 4.0 - C_e, 0.0)) : 0.0

    # ---- Rubisco-limited photosynthesis (JC) ----
    k2 = kc * (1.0 + OX / ko)
    B_c = dark_resp + vcmax + g0 * (co2_air_mol + k2)
    C_c = vcmax * g0 * (co2_air_mol - gam) + vcmax * dark_resp
    jc_stress = B_c / 2.0 - sqrt(max(B_c^2 / 4.0 - C_c, 0.0))

    # ---- Gross photosynthesis ----
    gpp_mol = min(je_stress, jc_stress) * hit_inhib
    gpp_mol = isfinite(gpp_mol) ? max(gpp_mol, 0.0) : 0.0 #mol(CO2)/m^2(leaf area) / s

    # 2. Scale by LAI to get per ground area (m-2 ground)
    # If your 'gpp' is currently per m-2 leaf:
    gpp_ground_daily = gpp_mol * LAI * mol_to_gC_day

    # 3. Final value for comparison
    # This matches the "gC m-2 day-1" unit in your metadata
    gpp = isfinite(gpp_ground_daily) ? max(gpp_ground_daily, 0.0) : 0.0

    
    @pack_nt begin
        gpp ⇒ land.fluxes
        vcmax ⇒ land.diagnostics
        jmax ⇒ land.diagnostics
        je_stress ⇒ land.diagnostics
        jc_stress ⇒ land.diagnostics
    end

    return land
end

purpose(::Type{gpp_JSBACH}) = "Calculate GPP based on the JSBACH C3 photosynthesis scheme with correct temperature scaling (K/C)."

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