export gppDiffRadiation_expCorrection

#! format: off
@bounds @describe @units @timescale @with_kw struct gppDiffRadiation_expCorrection{T1} <: gppDiffRadiation
	μ::T1 = 10.0 | (0.8, 20.0) | "" | "" | ""
end
#! format: on

function define(params::gppDiffRadiation_expCorrection, forcing, land, helpers)
	## unpack parameters and forcing
    @unpack_gppDiffRadiation_expCorrection params
    @unpack_nt (f_rg, f_rg_pot) ⇐ forcing

    ## calculate variables
    CI = one(μ) #@needscheck: this is different to Turner which does not have 1- . So, need to check if this correct
    CI_min = CI
    CI_max = CI
    @pack_nt (CI_min, CI_max) ⇒ land.gppDiffRadiation
	return land
end

function precompute(params::gppDiffRadiation_expCorrection, forcing, land, helpers)
	## unpack parameters and forcing
    @unpack_gppDiffRadiation_expCorrection params
    ## calculate variables
    gpp_f_cloud = one(μ)
    ## pack land variables
    @pack_nt gpp_f_cloud ⇒ land.diagnostics
	return land
end

function compute(params::gppDiffRadiation_expCorrection, forcing, land, helpers)
	## Automatically generated sample code for basis. Modify, correct, and use. define, precompute, and update methods can use similar coding when needed. When not, they can simply be deleted. 
	@unpack_gppDiffRadiation_expCorrection params # unpack the model parameters
	@unpack_nt (f_rg, f_rg_pot) ⇐ forcing

    @unpack_nt begin
        (CI_min, CI_max) ⇐ land.gppDiffRadiation
        z_zero ⇐ land.constants
        tolerance ⇐ helpers.numbers
    end

    ## calculate variables
    ## FROM SHANNING
    rg_frac = safe_divide(f_rg, f_rg_pot)

    CI = clamp_zero_one(one(rg_frac) - rg_frac) #@needscheck: this is different to Turner which does not have 1- . So, need to check if this correct

    # update the minimum and maximum on the go
    # CI_min = min(CI, CI_min)
    # CI_max = max(CI, CI_max)

    # CI_nor = clamp_zero_one(safe_divide(CI - CI_min, CI_max - CI_min)) # @needscheck: originally, CI_min and max were based on the year's data. see below.


    # cScGPP = one(μ) - μ * (one(μ) - CI_nor)
    cScGPP = one(μ) - CI ^ μ

    # gpp_f_cloud = f_rg_pot > zero(f_rg_pot) ? cScGPP : zero(cScGPP)
	gpp_f_cloud = f_rg_pot > zero(f_rg_pot) ? cScGPP : one(cScGPP)

    ## pack land variables
    @pack_nt gpp_f_cloud ⇒ land.diagnostics
    @pack_nt (CI_min, CI_max) ⇒ land.gppDiffRadiation

	return land
end

# function update(params::gppDiffRadiation_expCorrection, forcing, land, helpers)
# 	return land
# end

purpose(::Type{gppDiffRadiation_expCorrection}) = "Using a correction for Shanning's approach, i.e. CI^μ"

@doc """ 

	$(getModelDocString(gppDiffRadiation_expCorrection))

---

# Extended help

*References*

- Bao, S., Wutzler, T., Koirala, S., Cuntz, M., Ibrom, A., Besnard, S., Walther, S., Šigut, L., Moreno, A., Weber, U., Wohlfahrt, G., Cleverly, J., Migliavacca, M., Woodgate, W., Merbold, L., Veenendaal, E., & Carvalhais, N. (2022). Environment-sensitivity functions for gross primary productivity in light use efficiency models. Agricultural and Forest Meteorology, 312, 108708. https://doi.org/10.1016/j.agrformet.2021.108708
- Turner, D. P., Ritts, W. D., Styles, J. M., Yang, Z., Cohen, W. B., Law, B. E., & Thornton, P. E. (2006).  A diagnostic carbon flux model to monitor the effects of disturbance & interannual variation in  climate on regional NEP. Tellus B: Chemical & Physical Meteorology, 58[5], 476-490.  DOI: 10.1111/j.1600-0889.2006.00221.x


*Versions*
 - 1.0 on 08.03.2026 [xshan]

*Created by*
 - xshan

"""
gppDiffRadiation_expCorrection

