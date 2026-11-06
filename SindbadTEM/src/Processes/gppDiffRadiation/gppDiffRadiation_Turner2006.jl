export gppDiffRadiation_Turner2006

#! format: off
@bounds @describe @units @timescale @with_kw struct gppDiffRadiation_Turner2006{T1} <: gppDiffRadiation
    rue_ratio::T1 = 0.5 | (0.0001, 1.0) | "ratio of clear sky LUE to max LUE" | "" | ""
end
#! format: on

function define(params::gppDiffRadiation_Turner2006, forcing, land, helpers)
    ## unpack parameters
    @unpack_gppDiffRadiation_Turner2006 params

    ## calculate variables
    # empty range so that the first timestep with radiation sets both bounds
    CI_min = one(rue_ratio)
    CI_max = zero(rue_ratio)
    ## pack land variables
    @pack_nt (CI_min, CI_max) ⇒ land.diagnostics
    return land
end

function precompute(params::gppDiffRadiation_Turner2006, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppDiffRadiation_Turner2006 params
    ## calculate variables
    gpp_f_cloud = one(rue_ratio)
    ## pack land variables
    @pack_nt gpp_f_cloud ⇒ land.diagnostics
    return land
end

function compute(params::gppDiffRadiation_Turner2006, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppDiffRadiation_Turner2006 params
    @unpack_nt (f_rg, f_rg_pot) ⇐ forcing
    @unpack_nt begin
        (CI_min, CI_max) ⇐ land.diagnostics
        z_zero ⇐ land.constants
    end

    ## calculate variables
    has_rad = f_rg_pot > z_zero
    rg_frac = safe_divide(f_rg, f_rg_pot)
    CI = clamp_zero_one(one(rg_frac) - rg_frac)

    # Turner used the annual min and max of CI, which is not available online, so the
    # bounds are updated on the go over the whole simulation
    CI_min = has_rad ? min(CI, CI_min) : CI_min
    CI_max = has_rad ? max(CI, CI_max) : CI_max

    SCI = clamp_zero_one(safe_divide(CI - CI_min, CI_max - CI_min))

    cScGPP = rue_ratio + (one(rue_ratio) - rue_ratio) * SCI
    gpp_f_cloud = has_rad ? cScGPP : zero(cScGPP)

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
 - 1.1 on 22.10.2026 [skoirala | @dr-ko]: CI as cloudiness index 1 - f_rg/f_rg_pot, fixed running min-max scaling

*Created by*
 - mjung
 - ncarvalhais
"""
gppDiffRadiation_Turner2006
