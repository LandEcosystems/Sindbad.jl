export gppAirT_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct gppAirT_CASA{T1,T,T3,T4} <: gppAirT
    opt_airT::T1 = 25.0 | (5.0, 35.0) | "check in CASA code" | "°C" | ""
    opt_airT_A::T = 0.2 | (0.01, 0.3) | "increasing slope of sensitivity" | "" | ""
    opt_airT_B::T3 = 0.3 | (0.01, 0.5) | "decreasing slope of sensitivity" | "" | ""
    exp_airT::T4 = 10.0 | (9.0, 11.0) | "reference for exponent of sensitivity" | "" | ""
end
#! format: on

function compute(params::gppAirT_CASA, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppAirT_CASA params
    @unpack_nt f_airT_day ⇐ forcing
    @unpack_nt o_one ⇐ land.constants

    ## calculate variables
    # CALCULATE T1: account for effects of temperature stress reflects the empirical observation that plants in very cold habitats typically have low maximum rates
    # T1 = 0.8 + 0.02 * opt_airT - 0.0005 * opt_airT ^ 2 this would make sense if opt_airT would be the same everywhere.

    # first half of the response curve
    Tp1 = o_one / ((o_one + exp(opt_airT_A * -exp_airT)) * (o_one + exp(opt_airT_A * -exp_airT)))
    TC1 = o_one / Tp1
    T1 =
        TC1 / ((o_one + exp(opt_airT_A * (opt_airT - exp_airT - f_airT_day))) *
               (o_one + exp(opt_airT_A * (-opt_airT - exp_airT + f_airT_day))))

    # second half of the response curve
    Tp2 = o_one / ((o_one + exp(opt_airT_B * (-exp_airT))) * (o_one + exp(opt_airT_B * (-exp_airT))))
    TC2 = o_one / Tp2
    T2 =
        TC2 / ((o_one + exp(opt_airT_B * (opt_airT - exp_airT - f_airT_day))) *
               (o_one + exp(opt_airT_B * (-opt_airT - exp_airT + f_airT_day))))

    # get the scalar
    gpp_f_airT = ifelse(f_airT_day >= opt_airT, T2, T1)

    ## pack land variables
    @pack_nt gpp_f_airT ⇒ land.diagnostics
    return land
end

purpose(::Type{gppAirT_CASA}) = "Temperature effect on GPP based as implemented in CASA."

@doc """

$(getModelDocString(gppAirT_CASA))

---

# Extended help

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].
 - Potter, C., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003).  Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data & ecosystem  modeling 1982–1998. Global & Planetary Change, 39[3-4], 201-213.
 - Potter; C. S.; Randerson; J. T.; Field; C. B.; Matson; P. A.; Vitousek; P. M.; Mooney; H. A.  & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global  satellite & surface data. Global Biogeochemical Cycles, 7[4], 811-841.

*Versions*
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]: documentation & clean up  

*Created by*
 - ncarvalhais

*Notes*
"""
gppAirT_CASA
