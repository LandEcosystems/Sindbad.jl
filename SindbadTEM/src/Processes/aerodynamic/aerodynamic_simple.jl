export aerodynamic_simple

#! format: off
@bounds @describe @units @timescale @with_kw struct aerodynamic_simple{T1} <: aerodynamic
    href::T1      = 10.0 | (2.0, 50.0)  | "Reference Height for windspeed" | "m" | ""
    rz0::T1       = 0.1  | (0.01, 0.5)  | "Roughness Length Ratio" | "-" | ""
    vonKarman::T1 = 0.4  | (0.35, 0.45) | "von Karman constant" | "-" | ""
    veg_height::T1 = 10.0 | (0.1, 20.0) | "Vegetation height" | "m" | ""
end
#! format: on

function compute(params::aerodynamic_simple, forcing, land, helpers)

    @unpack_aerodynamic_simple params

    @unpack_nt begin
        f_windspeed ⇐ forcing
    end


    # 1. Calculate roughness length (z0) with a safety floor for bare soil
    z0 = max(rz0 * veg_height, 0.001)

    # 2. Calculate aerodynamic Conductance (ga) [m/s]
    # Equation: ga = (k² * u) / [ln(href / z0 + 1)]²
    # We add 1.0 inside the log as per the JSBACH snippet to avoid log(0)
    denom = log(href / z0 + 1.0)^2
    aerodynamic_conductance = (vonKarman^2 * f_windspeed) / denom

    # 3. Calculate aerodynamic Resistance (ra) [s/m]
    # Use a small epsilon to avoid division by zero in still air
    aerodynamic_resistance = 1.0 / max(aerodynamic_conductance, 1e-6)

    @pack_nt begin
        aerodynamic_resistance ⇒ land.diagnostics
        aerodynamic_conductance ⇒ land.diagnostics
    end

    return land
end

purpose(::Type{aerodynamic_simple}) =
    "Calculates aerodynamic resistance (ra) based on the logarithmic wind profile used in JSBACH."

@doc """
    $(getModelDocString(aerodynamic_simple))

---

# Extended help

Computes aerodynamic resistance (ra) using the neutral stability logarithmic profile:

    ga = (k² * u) / [ln(href / (rz0 * h_veg) + 1)]²
    ra = 1 / ga

Where:
- k: von Karman constant
- u: wind speed (m/s)
- href: reference measurement height (m)
- rz0: ratio of roughness length to vegetation height
"""
aerodynamic_simple