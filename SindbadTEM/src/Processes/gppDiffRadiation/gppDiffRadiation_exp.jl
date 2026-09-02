export gppDiffRadiation_exp

#! format: off
@bounds @describe @units @timescale @with_kw struct gppDiffRadiation_exp{T1} <: gppDiffRadiation
    # μ::T1 = 0.46 | (0.0001, 1.0) | "" | "" | ""
    μ::T1 = 0.5 | (0.0001, 1.0) | "" | "" | ""
end
#! format: on

function define(params::gppDiffRadiation_exp, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppDiffRadiation_exp params
    @unpack_nt (f_rg, f_rg_pot) ⇐ forcing

    ## calculate variables
    CI = one(μ) #@needscheck: this is different to Turner which does not have 1- . So, need to check if this correct
    CI_min = CI
    CI_max = CI
    @pack_nt (CI_min, CI_max) ⇒ land.gppDiffRadiation
    return land
end

function precompute(params::gppDiffRadiation_exp, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppDiffRadiation_exp params
    ## calculate variables
    gpp_f_cloud = one(μ)
    ## pack land variables
    @pack_nt gpp_f_cloud ⇒ land.diagnostics
    return land
end


function compute(params::gppDiffRadiation_exp, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppDiffRadiation_exp params

    @unpack_nt (f_rg, f_rg_pot) ⇐ forcing

    @unpack_nt begin
        (CI_min, CI_max) ⇐ land.gppDiffRadiation
        z_zero ⇐ land.constants
        tolerance ⇐ helpers.numbers
    end

    ## calculate variables
    ## FROM SHANNING
    rg_frac = getFrac(f_rg, f_rg_pot)

    CI = clampZeroOne(one(rg_frac) - rg_frac) #@needscheck: this is different to Turner which does not have 1- . So, need to check if this correct

    # update the minimum and maximum on the go
    # CI_min = min(CI, CI_min)
    # CI_max = max(CI, CI_max)

    # CI_nor = clampZeroOne(getFrac(CI - CI_min, CI_max - CI_min)) # @needscheck: originally, CI_min and max were based on the year's data. see below.


    # cScGPP = one(μ) - μ * (one(μ) - CI_nor)
    cScGPP = CI ^ μ

    gpp_f_cloud = f_rg_pot > zero(f_rg_pot) ? cScGPP : zero(cScGPP)

    ## pack land variables
    @pack_nt gpp_f_cloud ⇒ land.diagnostics
    @pack_nt (CI_min, CI_max) ⇒ land.gppDiffRadiation
    return land
end

@doc """
cloudiness scalar [radiation diffusion] on gpp_potential based on exp

# Parameters
$(getModelDocString(gppDiffRadiation_exp))

---

# compute:

*Inputs*
 - forcing.f_rg: Global radiation [SW incoming] [MJ/m2/time]
 - forcing.f_rg_pot: Potential radiation [MJ/m2/time]
 - rue_ratio : ratio of clear sky LUE to max LUE  in turner et al., appendix A, e_[g_cs] / e_[g_max], should be between 0 & 1

*Outputs*
 - land.diagnostics.gpp_f_cloud: effect of cloudiness on potential GPP

---

# Extended help

*References*
 - Turner, D. P., Ritts, W. D., Styles, J. M., Yang, Z., Cohen, W. B., Law, B. E., & Thornton, P. E. (2006).  A diagnostic carbon flux model to monitor the effects of disturbance & interannual variation in  climate on regional NEP. Tellus B: Chemical & Physical Meteorology, 58[5], 476-490.  DOI: 10.1111/j.1600-0889.2006.00221.x

*Versions*
 - 1.0 on 22.11.2019 [skoirala]: documentation & clean up
 - 1.1 on 22.01.2021 [skoirala]: minimum & maximum function had []  missing & were not working  

*Created by:*
 - mjung
 - ncarvalhais
"""
gppDiffRadiation_exp
