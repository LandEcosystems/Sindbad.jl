export lignin_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct lignin_CASA{T1,T2,T3} <: lignin
    lit_frac_C_lignin::T1 = 0.65 | (0.0, 1.0) | "carbon fraction of lignin" | "fraction" | ""
    lit_k_f_lignin_A::T2 = 3.0 | (0.0, 10.0) | "sensitivity of the structural litter decomposition rate to the structural lignin fraction" | "" | ""
    lit_frac_lignin_wood::T3 = 0.4 | (0.0, 1.0) | "lignin fraction of woody litter" | "fraction" | ""
end
#! format: on

function precompute(params::lignin_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_lignin_CASA params

    ## unpack land variables
    @unpack_nt begin
        (lit_frac_lignin, lit_frac_metabolic, lit_nonsol_to_sol_lignin) ⇐ land.properties
        o_one ⇐ land.constants
    end

    ## calculate variables
    # Lignin is present only in the structural litter fraction, so the lignin
    # content of litter is rescaled by the structural fraction of litter,
    # 1 - lit_frac_metabolic.
    lit_frac_lignin_struct = clamp_zero_one(
        (lit_frac_lignin * lit_frac_C_lignin * lit_nonsol_to_sol_lignin) /
        (o_one - lit_frac_metabolic))

    # effect of lignin content on the decomposition rate of the structural
    # litter pools
    lit_k_f_lignin = exp(-lit_k_f_lignin_A * lit_frac_lignin_struct)

    ## pack land variables
    @pack_nt (lit_frac_C_lignin, lit_frac_lignin_struct, lit_frac_lignin_wood, lit_k_f_lignin) ⇒ land.properties
    return land
end

purpose(::Type{lignin_CASA}) = "Structural lignin fraction and its effect on litter decomposition rates as modeled in CASA."

@doc """

	$(getModelDocString(lignin_CASA))

---

# Extended help

The approach computes

`lit_frac_lignin_struct = clamp_zero_one(lit_frac_lignin * lit_frac_C_lignin * lit_nonsol_to_sol_lignin / (1 - lit_frac_metabolic))`

`lit_k_f_lignin = exp(-lit_k_f_lignin_A * lit_frac_lignin_struct)`

from the litter chemistry published by [`metabolicFraction`](@ref), so the
per-PFT lignin content is declared in exactly one place.

The division by `1 - lit_frac_metabolic` needs no guard: `metabolicFraction_none`
sets the metabolic fraction to zero, and `metabolicFraction_CASA` bounds it by
`lit_frac_metabolic_A`, which is below one. A `metabolicFraction_constant` with
`lit_frac_metabolic` set to exactly one is the only degenerate case, and
`clamp_zero_one` bounds the result even then.

This replaces the lignin part of the legacy `cTauVegProperties_CASA`.

*References*
 - Carvalhais, N., Reichstein, M., Seixas, J., Collatz, G. J., Pereira, J. S., Berbigier, P., & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for biogeochemical modeling performance and inverse parameter retrieval. Global Biogeochemical Cycles, 22(2).
 - Potter, C. S., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003). Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data and ecosystem modeling 1982-1998. Global and Planetary Change, 39(3-4), 201-213.
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: extracted from cTauVegProperties_CASA

*Created by*
 - ncarvalhais

"""
lignin_CASA
