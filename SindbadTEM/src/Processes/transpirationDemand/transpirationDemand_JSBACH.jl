export transpirationDemand_JSBACH

*#! format: off*

@bounds @describe @units @timescale @with_kw struct transpirationDemand_JSBACH{T1} <: transpirationDemand

    cp::T1 = 1005.0 | (1000.0, 1010.0) | "Specific heat of air" | "J/kg/K" | ""

end

*#! format: on*

function compute(params::transpirationDemand_JSBACH, forcing, land, helpers)

    @unpack_transpirationDemand_JSBACH params

    @unpack_nt begin

        f_airT ⇐ forcing
        f_psurf ⇐ forcing
        f_VPD ⇐ forcing
        f_RH ⇐ forcing

        aerodynamic_resistance ⇐ land.diagnostics
        canopy_cond_limited ⇐ land.diagnostics

        (const_tmelt, Rd, epsilon, Rho, d_to_s, o_one) ⇐ land.constants

    end

    # ---------------------------------------------------------
    # Numerical constants
    # ---------------------------------------------------------

    e_sat_ref = oftype(f_airT, 610.78)
    e_sat_a   = oftype(f_airT, 17.27)
    e_sat_b   = oftype(f_airT, 237.3)
    rh_scale  = oftype(f_RH, 100.0)
    gs_floor  = oftype(canopy_cond_limited, 1e-20)

    # ---------------------------------------------------------
    # 1. Saturation vapor pressure (Pa)
    #    Tetens-like formulation
    # ---------------------------------------------------------

    e_sat =
        e_sat_ref *
        exp(
            (e_sat_a * f_airT) /
            (f_airT + e_sat_b)
        )

    # ---------------------------------------------------------
    # 2. Actual vapor pressure from relative humidity
    #    f_RH is given in %
    # ---------------------------------------------------------

    RH_frac = f_RH / rh_scale

    e_air = RH_frac * e_sat

    # ---------------------------------------------------------
    # 3. Specific humidity
    # ---------------------------------------------------------

    q_a   = epsilon * e_air / f_psurf
    q_sat = epsilon * e_sat / f_psurf

    dq = q_a - q_sat

    # ---------------------------------------------------------
    # 4. Resistances
    # ---------------------------------------------------------

    rs = o_one / max(canopy_cond_limited, gs_floor)

    r_total = aerodynamic_resistance + rs

    # ---------------------------------------------------------
    # 5. Transpiration flux
    # ---------------------------------------------------------

    et_flux = Rho * dq / r_total

    # Convert from per second to per day
    transpiration_demand = abs(et_flux) * d_to_s

    @pack_nt begin
        transpiration_demand ⇒ land.diagnostics
    end

    return land
end

purpose(::Type{transpirationDemand_JSBACH}) =
    "Physical transpirationDemand calculation using resistance network and humidity gradients."

@doc """

$(getModelDocString(transpirationDemand_JSBACH))

---

# Extended help

*References*

*Versions*

 - 1.0 on 22.11.2019 [skoirala | @dr-ko]

*Created by*

 - mjung

 - skoirala | @dr-ko

*Notes*

"""

transpirationDemand_JSBACH