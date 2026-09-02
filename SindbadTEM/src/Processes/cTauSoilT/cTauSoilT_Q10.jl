export cTauSoilT_Q10

#! format: off
@bounds @describe @units @timescale @with_kw struct cTauSoilT_Q10{T1,T2,T3} <: cTauSoilT
    # Q10::T1 = 1.4 | (1.05, 3.0) | "" | "" | ""
    Q10::T1 = 2.0 | (1.05, 3.0) | "" | "" | ""
    ref_airT::T2 = 30.0 | (0.01, 40.0) | "" | "°C" | ""
    Q10_base::T3 = 10.0 | (-Inf, Inf) | "base temperature difference" | "°C" | ""
end
#! format: on

function compute(params::cTauSoilT_Q10, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_cTauSoilT_Q10 params
    @unpack_nt f_airT ⇐ forcing

    ## calculate variables
    # CALCULATE EFFECT OF TEMPERATURE ON SOIL CARBON FLUXES
    c_eco_k_f_soilT = Q10^((f_airT - ref_airT) / Q10_base)

    ## pack land variables
    @pack_nt c_eco_k_f_soilT ⇒ land.diagnostics
    return land
end

purpose(::Type{cTauSoilT_Q10}) = "Effect of soil temperature on decomposition rates using a Q10 function."

@doc """

$(getModelDocString(cTauSoilT_Q10))

---

# Extended help

*References*

*Versions*
 - 1.0 on 12.01.2020 [sbesnard]  

*Created by*
 - ncarvalhais

*Notes*
"""
cTauSoilT_Q10
