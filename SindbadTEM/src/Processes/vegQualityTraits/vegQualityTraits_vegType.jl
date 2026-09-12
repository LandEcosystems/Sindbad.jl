export vegQualityTraits_vegType

#! format: off
@bounds @describe @units @timescale @with_kw struct vegQualityTraits_vegType{T1,T2,T3,T4,T5,T6,T7,T8} <: vegQualityTraits
    lit_frac_metabolic_A::T1 = 0.85 | (0.0, 1.0) | "intercept of the metabolic litter fraction at zero lignin-to-nitrogen ratio" | "fraction" | ""
    lit_frac_metabolic_B::T2 = 0.018 | (0.0, 0.1) | "sensitivity of the metabolic litter fraction to the lignin-to-nitrogen ratio" | "fraction" | ""
    lit_nonsol_to_sol_lignin::T3 = 2.22 | (1.0, 5.0) | "scalar converting nonsoluble to soluble lignin" | "fraction" | ""
    lit_frac_lignin_scalar::T4 = 1.0 | (0.25, 4.0) | "scalar for the per-PFT lignin fraction of litter" | "-" | ""
    lit_CN_ratio_scalar::T5 = 1.0 | (0.25, 4.0) | "scalar for the per-PFT carbon-to-nitrogen ratio of litter" | "-" | ""
    lit_frac_C_lignin::T6 = 0.65 | (0.0, 1.0) | "carbon fraction of lignin" | "fraction" | ""
    lit_k_f_lignin_A::T7 = 3.0 | (0.0, 10.0) | "sensitivity of the structural litter decomposition rate to the structural lignin fraction" | "" | ""
    lit_frac_lignin_wood::T8 = 0.4 | (0.0, 1.0) | "lignin fraction of woody litter" | "fraction" | ""
end
#! format: on

function define(params::vegQualityTraits_vegType, forcing, land, helpers)
    @unpack_nt veg_type_class_map ⇐ land.vegClassMap

    # Re-keyed once, at define time, onto whichever classification the experiment's
    # vegClassMap approach resolved into (the canonical vocabulary, or a grouping like
    # VegTypeCatalog_PlantForm) -- see vegTypeCatalogFor.
    lit_CN_ratio_per_vegtype = vegTypeCatalogFor(LIT_CN_RATIO_PER_VEGTYPE, typeof(veg_type_class_map))
    lit_frac_lignin_per_vegtype = vegTypeCatalogFor(LIT_FRAC_LIGNIN_PER_VEGTYPE, typeof(veg_type_class_map))

    @pack_nt (lit_CN_ratio_per_vegtype, lit_frac_lignin_per_vegtype) ⇒ land.diagnostics
    return land
end

function precompute(params::vegQualityTraits_vegType, forcing, land, helpers)
    ## unpack parameters
    @unpack_vegQualityTraits_vegType params

    ## unpack land variables
    @unpack_nt begin
        lit_CN_ratio_per_vegtype ⇐ land.diagnostics
        lit_frac_lignin_per_vegtype ⇐ land.diagnostics
        veg_type_name ⇐ land.states
        o_one ⇐ land.constants
    end

    ## calculate variables
    # Select the litter chemistry of land.states.veg_type_name, whatever classification
    # (fine canonical, or a grouping such as tree/shrub/herb) produced it, by name
    # rather than by a positional index into an array. The per-vegetation-type tables
    # are plain Float64 literals; oftype matches each looked-up value to its scalar's
    # type before multiplying, so the result stays the parameter type instead of
    # silently widening to Float64.
    lit_CN_ratio = oftype(lit_CN_ratio_scalar, getproperty(lit_CN_ratio_per_vegtype, veg_type_name)) * lit_CN_ratio_scalar
    lit_frac_lignin = oftype(lit_frac_lignin_scalar, getproperty(lit_frac_lignin_per_vegtype, veg_type_name)) * lit_frac_lignin_scalar

    # lignin-to-nitrogen ratio of litter
    lignin_to_N = (lit_CN_ratio * lit_frac_lignin) * lit_nonsol_to_sol_lignin

    # the metabolic fraction of litter decreases linearly with the
    # lignin-to-nitrogen ratio
    lit_frac_metabolic = clamp_zero_one(lit_frac_metabolic_A - lit_frac_metabolic_B * lignin_to_N)

    # lignin is present only in the structural litter fraction, so the lignin
    # content of litter is rescaled by the structural fraction of litter,
    # 1 - lit_frac_metabolic
    lit_frac_lignin_struct = clamp_zero_one(
        (lit_frac_lignin * lit_frac_C_lignin * lit_nonsol_to_sol_lignin) /
        (o_one - lit_frac_metabolic))

    # effect of lignin content on the decomposition rate of the structural
    # litter pools
    lit_k_f_lignin = exp(-lit_k_f_lignin_A * lit_frac_lignin_struct)

    ## pack land variables
    @pack_nt begin
        (lit_CN_ratio, lit_frac_lignin, lit_frac_metabolic, lit_nonsol_to_sol_lignin) ⇒ land.properties
        (lit_frac_C_lignin, lit_frac_lignin_struct, lit_frac_lignin_wood, lit_k_f_lignin) ⇒ land.properties
    end
    return land
end

purpose(::Type{vegQualityTraits_vegType}) = "Metabolic litter fraction and the structural lignin fraction, with vegetation-type-dependent litter chemistry, and the lignin effect on decomposition rate, as modeled in CASA."

@doc """

	$(getModelDocString(vegQualityTraits_vegType))

---

# Extended help

The approach re-keys `LIT_FRAC_LIGNIN_PER_VEGTYPE` and `LIT_CN_RATIO_PER_VEGTYPE`
(declared in `ParamsForVegClasses.jl`) onto whichever classification the experiment's
`vegClassMap` approach resolved into (`define`), then looks up the lignin fraction and
the carbon-to-nitrogen ratio of litter for `land.states.veg_type_name` (`precompute`), each
scaled by a bounded, optimizable multiplier (`lit_frac_lignin_scalar`,
`lit_CN_ratio_scalar`) since the per-vegetation-type tables themselves are fixed data
excluded from optimization, forms the lignin-to-nitrogen ratio

`lignin_to_N = lit_CN_ratio * lit_frac_lignin * lit_nonsol_to_sol_lignin`

and computes

`lit_frac_metabolic = clamp_zero_one(lit_frac_metabolic_A - lit_frac_metabolic_B * lignin_to_N)`

Lignin-rich, nitrogen-poor litter therefore yields a smaller metabolic fraction
and a larger structural fraction. Lignin is present only in that structural
fraction, so it is rescaled by `1 - lit_frac_metabolic` to give the structural
lignin fraction:

`lit_frac_lignin_struct = clamp_zero_one(lit_frac_lignin * lit_frac_C_lignin * lit_nonsol_to_sol_lignin / (1 - lit_frac_metabolic))`

`lit_k_f_lignin = exp(-lit_k_f_lignin_A * lit_frac_lignin_struct)`

This used to be two approaches, `metabolicFraction_CASA` and `lignin_CASA`, with the
second reading the first's output back from `land.properties`. Merged into one so the
per-vegetation-type litter chemistry and the lignin effect it drives are always
computed consistently, with no dependency on a matching separate selection.

This replaces the metabolic-fraction and lignin parts of the legacy
`cTauVegProperties_CASA`, where `MTF` was clipped with a MATLAB-style logical index
that never ran in Julia; `clamp_zero_one` also bounds the fraction above, which the
original did not.

*References*
 - Carvalhais, N., Reichstein, M., Seixas, J., Collatz, G. J., Pereira, J. S., Berbigier, P., & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for biogeochemical modeling performance and inverse parameter retrieval. Global Biogeochemical Cycles, 22(2).
 - Potter, C. S., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003). Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data and ecosystem modeling 1982-1998. Global and Planetary Change, 39(3-4), 201-213.
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: extracted from cTauVegProperties_CASA, as separate metabolicFraction_CASA and lignin_CASA approaches
 - 2.0 on 09.09.2026 [skoirala]: merged metabolicFraction_CASA and lignin_CASA into vegQualityTraits_VegTypes
 - 3.0 on 10.09.2026 [skoirala]: per-PFT litter chemistry keyed by canonical
   PFT name (PFTCatalog_SINDBAD_PFT) instead of a positional index into an
   array tied to one specific classification; the two per-PFT arrays became
   fixed named lookups plus bounded scalar multipliers, since array-valued
   struct fields cannot be optimized
 - 4.0 on 10.09.2026 [skoirala]: the fixed tables moved to the consolidated
   `vegTypeParamCatalog.jl`; a new `define` re-keys them at experiment setup
   time onto the active `vegClassMap` classification via `vegTypeCatalogFor`
   instead of `precompute` reading them directly by canonical PFT name
 - 5.0 on 12.09.2026 [skoirala]: renamed from `vegQualityTraits_VegTypes` to
   `vegQualityTraits_vegType`

*Created by*
 - ncarvalhais

"""
vegQualityTraits_vegType
