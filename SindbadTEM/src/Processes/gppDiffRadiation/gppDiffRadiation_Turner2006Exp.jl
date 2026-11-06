export gppDiffRadiation_Turner2006Exp

#! format: off
@bounds @describe @units @timescale @with_kw struct gppDiffRadiation_Turner2006Exp{T1,T2} <: gppDiffRadiation
    rue_ratio::T1 = 0.5 | (0.0001, 1.0) | "ratio of clear sky LUE to max LUE" | "" | ""
    μ::T2 = 1.0 | (0.2, 5.0) | "shape exponent of the response to scaled cloudiness index" | "" | ""
end
#! format: on

function define(params::gppDiffRadiation_Turner2006Exp, forcing, land, helpers)
    ## unpack parameters
    @unpack_gppDiffRadiation_Turner2006Exp params

    ## calculate variables
    # empty range so that the first timestep with radiation sets both bounds
    CI_min = one(rue_ratio)
    CI_max = zero(rue_ratio)
    ## pack land variables
    @pack_nt (CI_min, CI_max) ⇒ land.diagnostics
    return land
end

function precompute(params::gppDiffRadiation_Turner2006Exp, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppDiffRadiation_Turner2006Exp params
    ## calculate variables
    gpp_f_cloud = one(rue_ratio)
    ## pack land variables
    @pack_nt gpp_f_cloud ⇒ land.diagnostics
    return land
end

function compute(params::gppDiffRadiation_Turner2006Exp, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppDiffRadiation_Turner2006Exp params
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

    # branch at SCI = 0 keeps the derivative with respect to μ finite, as 0^μ would
    # need log(0)
    SCI_μ = SCI > zero(SCI) ? SCI ^ μ : zero(SCI) * zero(μ)

    cScGPP = rue_ratio + (one(rue_ratio) - rue_ratio) * SCI_μ
    gpp_f_cloud = has_rad ? cScGPP : zero(cScGPP)

    ## pack land variables
    @pack_nt (gpp_f_cloud, CI_min, CI_max) ⇒ land.diagnostics
    return land
end

purpose(::Type{gppDiffRadiation_Turner2006Exp}) = "Cloudiness scalar (radiation diffusion) on GPP potential based on Turner (2006), with a power-law response to the scaled cloudiness index."

@doc """

$(getModelDocString(gppDiffRadiation_Turner2006Exp))

---

# Extended help

gpp_f_cloud = rue_ratio + (1 - rue_ratio) * SCI^μ, where SCI is the cloudiness index
1 - f_rg/f_rg_pot scaled between its running minimum and maximum. μ = 1 gives
gppDiffRadiation_Turner2006, μ < 1 saturates the diffuse benefit under light cloud,
and μ > 1 limits it to heavy cloud.

*References*
 - Turner, D. P., Ritts, W. D., Styles, J. M., Yang, Z., Cohen, W. B., Law, B. E., & Thornton, P. E. (2006).  A diagnostic carbon flux model to monitor the effects of disturbance & interannual variation in  climate on regional NEP. Tellus B: Chemical & Physical Meteorology, 58[5], 476-490.  DOI: 10.1111/j.1600-0889.2006.00221.x

*Versions*
 - 1.0 on 27.10.2026 [skoirala | @dr-ko]: copy of gppDiffRadiation_Turner2006 with a power-law exponent μ on SCI

*Created by*
 - skoirala
"""
gppDiffRadiation_Turner2006Exp
