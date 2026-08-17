export gppDiffRadiation_Turner2006

#! format: off
@bounds @describe @units @timescale @with_kw struct gppDiffRadiation_Turner2006{T1} <: gppDiffRadiation
    rue_ratio::T1 = 0.5 | (0.0001, 1.0) | "ratio of clear sky LUE to max LUE" | "" | ""
end
#! format: on

function define(params::gppDiffRadiation_Turner2006, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppDiffRadiation_Turner2006 params
    @unpack_nt (f_rg, f_rg_pot) ⇐ forcing

    ## calculate variables
    CI = f_rg / f_rg_pot
    CI_min = CI
    CI_max = CI
    ## pack land variables
    @pack_nt (CI_min, CI_max) ⇒ land.diagnostics
    return land
end

function compute(params::gppDiffRadiation_Turner2006, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppDiffRadiation_Turner2006 params
    @unpack_nt (f_rg, f_rg_pot) ⇐ forcing
    @unpack_nt begin
        (CI_min, CI_max) ⇐ land.diagnostics
        z_zero ⇐ land.constants
        tolerance ⇐ helpers.numbers
    end

    ## calculate variables
    CI = f_rg / f_rg_pot

    # update the minimum and maximum on the go
    CI_min = min(CI, CI_min)
    CI_max = min(CI, CI_max)

    SCI = (CI - CI_min) / (CI_max - CI_min + tolerance) # @needscheck: originally, CI_min and max were calculated in the instantiate using the full time series of f_rg and f_rg_pot. Now, this is not possible, and thus min and max need to be updated on the go, and once the simulation is complete in the first cycle of forcing, it will work...

    cScGPP = (one(rue_ratio) - rue_ratio) * SCI + rue_ratio
    gpp_f_cloud = ifelse(f_rg_pot > z_zero, cScGPP, zero(cScGPP))

    ## pack land variables
    @pack_nt (gpp_f_cloud, CI_min, CI_max) ⇒ land.diagnostics
    return land
end

purpose(::Type{gppDiffRadiation_Turner2006}) = "Cloudiness scalar (radiation diffusion) on GPP potential based on Turner (2006)."

@doc """

$(getModelDocString(gppDiffRadiation_Turner2006))

---

# Extended help

*References*
 - Turner, D. P., Ritts, W. D., Styles, J. M., Yang, Z., Cohen, W. B., Law, B. E., & Thornton, P. E. (2006).  A diagnostic carbon flux model to monitor the effects of disturbance & interannual variation in  climate on regional NEP. Tellus B: Chemical & Physical Meteorology, 58[5], 476-490.  DOI: 10.1111/j.1600-0889.2006.00221.x

*Versions*
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]: documentation & clean up 

*Created by*
 - mjung
 - ncarvalhais
"""
gppDiffRadiation_Turner2006
