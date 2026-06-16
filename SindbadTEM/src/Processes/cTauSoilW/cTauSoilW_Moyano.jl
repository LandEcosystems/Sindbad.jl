export cTauSoilW_Moyano

#! format: off
@bounds @describe @units @timescale @with_kw struct cTauSoilW_Moyano{T1,T2,T3,T4,T5} <: cTauSoilW
    opt_soilW::T1 = 63.0 | (50.0, 95.0) | "Optimal moisture for decomposition" | "percent degree of saturation" | ""
    opt_soilW_A::T2 = 0.2 | (0.1, 0.3) | "slope of increase" | "per percent" | ""
    opt_soilW_B::T3 = 0.3 | (0.15, 0.5) | "slope of decrease" | "per percent" | ""
    opt_soilW_a::T3 = 2.5 | (0.05, 8.5) | "curvature, moisture sensitivity" | "" | ""
    w_exp::T4 = 10.0 | (-Inf, Inf) | "reference for exponent of sensitivity" | "per percent" | ""
    frac_to_perc::T5 = 100.0 | (-Inf, Inf) | "unit converter for fraction to percent" | "" | ""
end
#! format: on

function define(params::cTauSoilW_Moyano, forcing, land, helpers)
    @unpack_cTauSoilW_Moyano params
    @unpack_nt cEco ⇐ land.pools

    ## Instantiate variables
    c_eco_k_f_soilW = one.(cEco)

    ## pack land variables
    @pack_nt c_eco_k_f_soilW ⇒ land.diagnostics
    return land
end

function compute(params::cTauSoilW_Moyano, forcing, land, helpers)
    ## unpack parameters
    @unpack_cTauSoilW_Moyano params

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
    soilW_top_sc = fSoilW_cTau_Moyano(w_one, opt_soilW_A, opt_soilW_B, w_exp, opt_soilW, soilW_top)
    cLitZix = getZix(cLit, helpers.pools.zix.cLit)
    for l_zix ∈ cLitZix
        @rep_elem soilW_top_sc ⇒ (c_eco_k_f_soilW, l_zix, :cEco)
    end

    ## repeat for the soil pools; using all soil moisture layers
    soilW_all = min(frac_to_perc * sum(soilW) / sum(w_sat), frac_to_perc)
    soilW_all_sc = fSoilW_cTau_Moyano(w_one, opt_soilW_A, opt_soilW_B, w_exp, opt_soilW, soilW_all)
    soilW_all_sc = fSoilW_cTau_GSI(w_one, opt_soilW_A, opt_soilW_B, w_exp, opt_soilW, soilW_all)

    cSoilZix = getZix(cSoil, helpers.pools.zix.cSoil)
    for s_zix ∈ cSoilZix
        @rep_elem soilW_all_sc ⇒ (c_eco_k_f_soilW, s_zix, :cEco)
    end

    ## pack land variables
    @pack_nt c_eco_k_f_soilW ⇒ land.diagnostics
    return land
end


function fSoilW_cTau_GSI(the_one, A, B, wExp, wOpt, wSoil)
    # first half of the response curve
    W2p1 = the_one / ((the_one + exp(A * -wExp)) * (the_one + exp(A * -wExp)))
    W2C1 = the_one / W2p1
    W21 = W2C1 / ((the_one + exp(A * (wOpt - wExp - wSoil))) * (the_one + exp(A * (-wOpt - wExp + wSoil))))

    # second half of the response curve
    W2p2 = the_one / ((the_one + exp(B * -wExp)) * (the_one + exp(B * -wExp)))
    W2C2 = the_one / W2p2
    T22 = W2C2 / ((the_one + exp(B * (wOpt - wExp - wSoil))) * (the_one + exp(B * (-wOpt - wExp + wSoil))))

    # combine the response curves
    soilW_sc = wSoil >= wOpt ? T22 : W21
    return soilW_sc
end

function fSoilW_cTau_Moyano(the_one, A, B, wExp, wOpt, wSoil)
    # first half of the response curve
    W2p1 = the_one / ((the_one + exp(A * -wExp)) * (the_one + exp(A * -wExp)))
    W2C1 = the_one / W2p1
    W21 = W2C1 / ((the_one + exp(A * (wOpt - wExp - wSoil))) * (the_one + exp(A * (-wOpt - wExp + wSoil))))

    # second half of the response curve
    W2p2 = the_one / ((the_one + exp(B * -wExp)) * (the_one + exp(B * -wExp)))
    W2C2 = the_one / W2p2
    T22 = W2C2 / ((the_one + exp(B * (wOpt - wExp - wSoil))) * (the_one + exp(B * (-wOpt - wExp + wSoil))))

    # combine the response curves
    soilW_sc = wSoil >= wOpt ? T22 : W21
    return soilW_sc
end

purpose(::Type{cTauSoilW_Moyano}) = "Effect of soil moisture on decomposition rates based on the Moyano13 eq.1."

@doc """

$(getModelDocString(cTauSoilW_Moyano))

---

# Extended help

*References*
 - Moyano F, Vasilyeva N & Menichetti L (2018) Diffusion limitations and Michaelis–Menten kinetics as drivers of combined temperature and moisture effects on carbon fluxes of mineral soils. Biogeosciences, Copernicus GmbH (15) 5031–5045 10.5194/bg-15-5031-2018
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].
 - Potter, C., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003).  Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data & ecosystem  modeling 1982–1998. Global & Planetary Change, 39[3-4], 201-213.
 - Potter; C. S.; Randerson; J. T.; Field; C. B.; Matson; P. A.; Vitousek; P. M.; Mooney; H. A.  & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global  satellite & surface data. Global Biogeochemical Cycles, 7[4], 811-841.

*Versions*
 - 1.0 on 15.06.2026 [twutz | @bgctw]

*Created by*
 - twutz | @bgctw

*Notes*
Moyano reports equation 1: response = 3.11 θS - 2.42 θS^2
which is a quadratic equation peaking at with two parameters, peaking
at `(θS_Opt,1.0)`.
This can be rewritten in terms of optimum and curvature by
a*(θS -θS_opt)^2+1, a is a sensitivity, i.e. stronger reduction
with deviations from optimal moisture.
The rational, here, is that at a given site, either the dry or
the wet side is important for reductions, but rarely both.
Hence, we parameterize only one sensitivity rather than two as in GSI.
"""
cTauSoilW_Moyano
