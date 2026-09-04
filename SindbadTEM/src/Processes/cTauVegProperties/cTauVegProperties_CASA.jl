export cTauVegProperties_CASA

struct cTauVegProperties_CASA <: cTauVegProperties end

function define(params::cTauVegProperties_CASA, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools

    ## Instantiate variables
    c_eco_k_f_veg_props = one.(cEco)

    ## pack land variables
    @pack_nt c_eco_k_f_veg_props ⇒ land.diagnostics
    return land
end

function precompute(params::cTauVegProperties_CASA, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_eco_k_f_veg_props ⇐ land.diagnostics
        lit_k_f_lignin ⇐ land.properties
    end

    ## calculate variables
    # Lignin slows the decomposition of the structural litter pools only. All
    # other pools keep the neutral factor of one set in define.
    for zix ∈ (helpers.pools.zix.cLitLeafS..., helpers.pools.zix.cLitRootFS...)
        @rep_elem lit_k_f_lignin ⇒ (c_eco_k_f_veg_props, zix, :cEco)
    end

    ## pack land variables
    @pack_nt c_eco_k_f_veg_props ⇒ land.diagnostics
    return land
end

purpose(::Type{cTauVegProperties_CASA}) = "Effect of litter lignin content on the decomposition rates of the structural litter pools, as modeled in CASA."

@doc """

$(getModelDocString(cTauVegProperties_CASA))

---

# Extended help

The approach applies `lit_k_f_lignin`, published by the [`lignin`](@ref)
process, to the structural litter pools `cLitLeafS` and `cLitRootFS`.

This approach previously owned the whole lignin calculation, with seven
parameters of its own. Those now live in [`metabolicFraction`](@ref) and
[`lignin`](@ref), so the lignin chemistry is declared once and shared with
`cQualityPartition`, which needs the same quantities.

It also previously contained a PFT-dependent turnover block that derived
`c_eco_τ` from a per-pool `AGE`. That block was a partial MATLAB translation
which read `p.cCycleBase` and `p.vegProperties`, neither of which exists in
SINDBAD, and packed a `c_eco_τ` that was never assigned, so the approach could
not run at all. It has been removed rather than guessed at; turnover rates come
from `cTau` and its `cTauSoilT`/`cTauSoilW`/`cTauLAI` factors.

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].
 - Potter, C., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003).  Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data & ecosystem  modeling 1982–1998. Global & Planetary Change, 39[3-4], 201-213.
 - Potter; C. S.; Randerson; J. T.; Field; C. B.; Matson; P. A.; Vitousek; P. M.; Mooney; H. A.  & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global  satellite & surface data. Global Biogeochemical Cycles, 7[4], 811-841.

*Versions*
 - 1.0 on 12.01.2020 [sbesnard]
 - 2.0 on 04.09.2026 [skoirala]: lignin properties moved to the lignin process; dead turnover block removed

*Created by*
 - ncarvalhais
"""
cTauVegProperties_CASA
