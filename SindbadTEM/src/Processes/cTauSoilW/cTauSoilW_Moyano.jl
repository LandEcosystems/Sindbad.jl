export cTauSoilW_Moyano

#! format: off
@bounds @describe @units @timescale @with_kw struct cTauSoilW_Moyano{T1,T2,T3} <: cTauSoilW
    opt_soilW::T1 = 63.0 | (50.0, 95.0) | "Optimal moisture for decomposition" | "percent degree of saturation" | ""
    opt_soilW_c::T2 = 2.5/1e4 | (0.1, 8.5) ./ 1e4 | "curvature, i.e.  moisture sensitivity" | "" | ""
    frac_to_perc::T3 = 100.0 | (-Inf, Inf) | "unit converter for fraction to percent" | "" | ""
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
    ## for the litter pools; only use the top layer"s moisture (litter layer)
    soilW_top = min(frac_to_perc * soilW[1] / w_sat[1], frac_to_perc)
    soilW_top_sc = fSoilW_cTau_Moyano(soilW_top, opt_soilW, opt_soilW_c, w_one)
    cLitZix = getZix(cLit, helpers.pools.zix.cLit)
    for l_zix ∈ cLitZix
        @rep_elem soilW_top_sc ⇒ (c_eco_k_f_soilW, l_zix, :cEco)
    end

    ## repeat for the soil pools; using all soil moisture layers
    # why sum rather than per layer?
    soilW_all = min(frac_to_perc * sum(soilW) / sum(w_sat), frac_to_perc)
    soilW_all_sc = fSoilW_cTau_Moyano(soilW_top, opt_soilW, opt_soilW_c, w_one)
    #soilW_all_sc_gsi = fSoilW_cTau_GSI(w_one, opt_soilW_A, opt_soilW_B, w_exp, opt_soilW, soilW_all)

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

function fSoilW_cTau_Moyano(wSoil::T, wOpt::T, c::T ,the_one=one(T)) where T
    the_one - c * abs2(wSoil - wOpt)
end

purpose(::Type{cTauSoilW_Moyano}) = "Effect of soil moisture on decomposition rates based on the Moyano13 eq.1."

@doc """

$(getModelDocString(cTauSoilW_Moyano))

---

# Extended help

*References*
 - Moyano F, Manzoni S & Chenu C (2013) Responses of soil heterotrophic respiration to moisture availability: An exploration of processes and models. Soil Biology and Biochemistry, Elsevier BV (59) 72–85 10.1016/j.soilbio.2013.01.002

*Versions*
 - 1.0 on 15.06.2026 [twutz | @bgctw]

*Created by*
 - twutz | @bgctw

*Notes*
Moyano reports equation 1: response = 3.11 θS - 2.42 θS^2
which is a quadratic equation peaking at with two parameters, peaking
at `(θS_Opt,1.0)`.
This can be rewritten in terms of optimum and curvature by
1 - c*(θS -θS_opt)^2, c is a sensitivity, i.e. stronger reduction
with deviations from optimal moisture.
The rational, here, is that at a given site, either the dry or
the wet side is important for reductions, but rarely both.
Hence, we parameterize only one sensitivity rather than two as in GSI.

Typical values of c are between 1 and 5 for θ given in vol/vol.
and (1..5)/100^2 if θ is given in percent.
"""
cTauSoilW_Moyano
