export aerodynamic_simple

#! format: off
@bounds @describe @units @timescale @with_kw struct aerodynamic_simple{T1} <: aerodynamics
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
        (z_zero, o_one) ⇐ land.constants
    end

    # 1. Calculate roughness length (z0) with a safety floor for bare soil
    z0_floor = oftype(z_zero, 0.001)
    z0 = max(rz0 * veg_height, z0_floor)

    # 2. Calculate aerodynamic conductance (ga) [m/s]
    #    ga = (k² * u) / [ln(href / z0 + 1)]²
    denom = log(href / z0 + o_one)^2

    aerodynamic_conductance =
        (vonKarman^2 * f_windspeed) / denom

    # 3. Calculate aerodynamic resistance (ra) [s/m]
    #    Use a small epsilon to avoid division by zero in still air
    ga_floor = oftype(aerodynamic_conductance, 1e-6)

    aerodynamic_resistance =
        o_one / max(aerodynamic_conductance, ga_floor)

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