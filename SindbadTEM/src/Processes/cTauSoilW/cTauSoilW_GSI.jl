export cTauSoilW_GSI

#! format: off
@bounds @describe @units @timescale @with_kw struct cTauSoilW_GSI{T1,T2,T3,T4,T5} <: cTauSoilW
    opt_soilW::T1 = 90.0 | (60.0, 95.0) | "Optimal moisture for decomposition" | "percent degree of saturation" | ""
    opt_soilW_A::T2 = 0.2 | (0.1, 0.3) | "slope of increase" | "per percent" | ""
    opt_soilW_B::T3 = 0.3 | (0.15, 0.5) | "slope of decrease" | "per percent" | ""
    w_exp::T4 = 10.0 | (-Inf, Inf) | "reference for exponent of sensitivity" | "per percent" | ""
    frac_to_perc::T5 = 100.0 | (-Inf, Inf) | "unit converter for fraction to percent" | "" | ""
end
#! format: on

function define(params::cTauSoilW_GSI, forcing, land, helpers)
    @unpack_cTauSoilW_GSI params
    @unpack_nt cEco ⇐ land.pools

    ## Instantiate variables
    c_eco_k_f_soilW = one.(cEco)

    ## pack land variables
    @pack_nt c_eco_k_f_soilW ⇒ land.diagnostics
    return land
end

function compute(params::cTauSoilW_GSI, forcing, land, helpers)
    ## unpack parameters
    @unpack_cTauSoilW_GSI params

    ## unpack land variables
    @unpack_nt c_eco_k_f_soilW ⇐ land.diagnostics

    ## unpack land variables
    @unpack_nt begin
        w_sat ⇐ land.properties
        (cEco, cLit, cSoil, soilW) ⇐ land.pools
    end
    w_one = one(eltype(soilW))
    ## for the litter pools; only use the top layer"s moisture
    soilW_top = min(frac_to_perc * soilW[1] / w_sat[1], frac_to_perc)
    soilW_top_sc = fSoilW_cTau(w_one, opt_soilW_A, opt_soilW_B, w_exp, opt_soilW, soilW_top)
    cLitZix = getZix(cLit, helpers.pools.zix.cLit)
    for l_zix ∈ cLitZix
        @rep_elem soilW_top_sc ⇒ (c_eco_k_f_soilW, l_zix, :cEco)
    end

    ## repeat for the soil pools; using all soil moisture layers
    soilW_all = min(frac_to_perc * sum(soilW) / sum(w_sat), frac_to_perc)
    soilW_all_sc = fSoilW_cTau(w_one, opt_soilW_A, opt_soilW_B, w_exp, opt_soilW, soilW_all)

    cSoilZix = getZix(cSoil, helpers.pools.zix.cSoil)
    for s_zix ∈ cSoilZix
        @rep_elem soilW_all_sc ⇒ (c_eco_k_f_soilW, s_zix, :cEco)
    end

    ## pack land variables
    @pack_nt c_eco_k_f_soilW ⇒ land.diagnostics
    return land
end

function fSoilW_cTau(the_one, A, B, wExp, wOpt, wSoil)
    # first half of the response curve
    W2p1 = the_one / ((the_one + exp(A * -wExp)) * (the_one + exp(A * -wExp)))
    W2C1 = the_one / W2p1
    W21 = W2C1 / ((the_one + exp(A * (wOpt - wExp - wSoil))) * (the_one + exp(A * (-wOpt - wExp + wSoil))))

    # second half of the response curve
    W2p2 = the_one / ((the_one + exp(B * -wExp)) * (the_one + exp(B * -wExp)))
    W2C2 = the_one / W2p2
    T22 = W2C2 / ((the_one + exp(B * (wOpt - wExp - wSoil))) * (the_one + exp(B * (-wOpt - wExp + wSoil))))

    # combine the response curves
    soilW_sc = ifelse(wSoil >= wOpt, T22, W21)
    return soilW_sc
end

purpose(::Type{cTauSoilW_GSI}) = "Effect of soil moisture on decomposition rates based on the GSI approach."

@doc """

$(getModelDocString(cTauSoilW_GSI))

---

# Extended help

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].
 - Potter, C., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003).  Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data & ecosystem  modeling 1982–1998. Global & Planetary Change, 39[3-4], 201-213.
 - Potter; C. S.; Randerson; J. T.; Field; C. B.; Matson; P. A.; Vitousek; P. M.; Mooney; H. A.  & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global  satellite & surface data. Global Biogeochemical Cycles, 7[4], 811-841.

*Versions*
 - 1.0 on 12.02.2021 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko

*Notes*
"""
cTauSoilW_GSI
