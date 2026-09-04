export metabolicFraction_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct metabolicFraction_CASA{T1,T2,T3,T4,T5} <: metabolicFraction
    lit_frac_metabolic_A::T1 = 0.85 | (0.0, 1.0) | "intercept of the metabolic litter fraction at zero lignin-to-nitrogen ratio" | "fraction" | ""
    lit_frac_metabolic_B::T2 = 0.018 | (0.0, 0.1) | "sensitivity of the metabolic litter fraction to the lignin-to-nitrogen ratio" | "fraction" | ""
    lit_nonsol_to_sol_lignin::T3 = 2.22 | (1.0, 5.0) | "scalar converting nonsoluble to soluble lignin" | "fraction" | ""
    lit_frac_lignin_per_PFT::T4 = Float64.([0.2, 0.2, 0.22, 0.25, 0.2, 0.15, 0.1, 0.0, 0.2, 0.15, 0.15, 0.1]) | (0.0, 1.0) | "fraction of litter that is lignin, per PFT class" | "fraction" | ""
    lit_C_to_N_per_PFT::T5 = Float64.([40.0, 50.0, 65.0, 80.0, 50.0, 50.0, 50.0, 0.0, 65.0, 50.0, 50.0, 40.0]) | (0.0, 150.0) | "carbon-to-nitrogen ratio of litter, per PFT class" | "gC/gN" | ""
end
#! format: on

function precompute(params::metabolicFraction_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_metabolicFraction_CASA params

    ## unpack land variables
    @unpack_nt PFT ⇐ land.states

    ## calculate variables
    # Select the litter chemistry of the PFT class of this pixel. PFT is a
    # one-based class index, so it is clamped to the length of the per-PFT
    # vectors rather than trusted blindly.
    ipft = clamp(round(Int, PFT), 1, length(lit_frac_lignin_per_PFT))
    lit_C_to_N = lit_C_to_N_per_PFT[ipft]
    lit_frac_lignin = lit_frac_lignin_per_PFT[ipft]

    # lignin-to-nitrogen ratio of litter
    lignin_to_N = (lit_C_to_N * lit_frac_lignin) * lit_nonsol_to_sol_lignin

    # the metabolic fraction of litter decreases linearly with the
    # lignin-to-nitrogen ratio
    lit_frac_metabolic = clamp_zero_one(lit_frac_metabolic_A - lit_frac_metabolic_B * lignin_to_N)

    ## pack land variables
    @pack_nt (lit_C_to_N, lit_frac_lignin, lit_frac_metabolic, lit_nonsol_to_sol_lignin) ⇒ land.properties
    return land
end

purpose(::Type{metabolicFraction_CASA}) = "Metabolic litter fraction as a linear function of the lignin-to-nitrogen ratio of litter, with PFT-dependent litter chemistry, as modeled in CASA."

@doc """

	$(getModelDocString(metabolicFraction_CASA))

---

# Extended help

The approach looks up the lignin fraction and the carbon-to-nitrogen ratio of
litter for the PFT class in `land.states.PFT`, forms the lignin-to-nitrogen
ratio

`lignin_to_N = lit_C_to_N * lit_frac_lignin * lit_nonsol_to_sol_lignin`

and computes

`lit_frac_metabolic = clamp_zero_one(lit_frac_metabolic_A - lit_frac_metabolic_B * lignin_to_N)`

Lignin-rich, nitrogen-poor litter therefore yields a smaller metabolic fraction
and a larger structural fraction. The litter chemistry is published alongside
the metabolic fraction so the [`lignin`](@ref) process can reuse it without
redeclaring the per-PFT vectors.

This replaces the metabolic-fraction part of the legacy
`cTauVegProperties_CASA`, where `MTF` was clipped with a MATLAB-style logical
index that never ran in Julia; `clamp_zero_one` also bounds the fraction above,
which the original did not.

*References*
 - Carvalhais, N., Reichstein, M., Seixas, J., Collatz, G. J., Pereira, J. S., Berbigier, P., & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for biogeochemical modeling performance and inverse parameter retrieval. Global Biogeochemical Cycles, 22(2).
 - Potter, C. S., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003). Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data and ecosystem modeling 1982-1998. Global and Planetary Change, 39(3-4), 201-213.
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: extracted from cTauVegProperties_CASA

*Created by*
 - ncarvalhais

"""
metabolicFraction_CASA
