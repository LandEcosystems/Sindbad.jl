export transpirationDemand_JSBACH

#! format: off
@bounds @describe @units @timescale @with_kw struct transpirationDemand_JSBACH{T1} <: transpirationDemand
    # Physical constants or scaling parameters if needed
    cp::T1 = 1005.0 | (1000.0, 1010.0) | "Specific heat of air" | "J/kg/K" | ""
end
#! format: on

function compute(params::transpirationDemand_JSBACH, forcing, land, helpers)
    @unpack_transpirationDemand_JSBACH params
    
    @unpack_nt begin
        f_airT ⇐ forcing          # Air temperature (°C)
        f_psurf ⇐ forcing         # Surface pressure (Pa)
        f_VPD ⇐ forcing           # Vapor Pressure Deficit (Pa)
        f_RH ⇐ forcing   # Relative Humidity (0–100 %)
        aerodynamic_resistance ⇐ land.diagnostics 
        canopy_cond_limited ⇐ land.diagnostics    # Stomatal conductance (m/s)
        (const_tmelt,Rd,epsilon,Rho) ⇐ land.constants
    end



    # -------------------------
    # 1. Saturation vapor pressure (Pa)
    # Tetens-like (consistent with most LSMs)
    # -------------------------
    e_sat = 610.78 * exp((17.27 * f_airT) / (f_airT + 237.3))

    # -------------------------
    # 2. Actual vapor pressure from f_RH
    # f_RH is %
    # -------------------------
    RH_frac = f_RH / 100.0
    e_air = RH_frac * e_sat

    # -------------------------
    # 3. Specific humidity
    # -------------------------
    q_a = epsilon * e_air / f_psurf
    q_sat = epsilon * e_sat / f_psurf

    dq = q_a - q_sat  


    # -------------------------
    # 4. Resistances
    # -------------------------
    rs = 1.0 / max(canopy_cond_limited, 1e-20)

    
    r_total = aerodynamic_resistance + rs

    # -------------------------
    # 5. Flux
    # -------------------------
    et_flux = Rho * dq / r_total

   
    transpiration_demand = abs(et_flux) * 86400.0

    
    @pack_nt begin
        transpiration_demand ⇒ land.diagnostics
    end

    return land
end

purpose(::Type{transpirationDemand_JSBACH}) = "Physical transpirationDemand calculation using resistance network and humidity gradients."

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
