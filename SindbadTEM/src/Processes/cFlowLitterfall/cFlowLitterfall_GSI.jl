export cFlowLitterfall_GSI

#! format: off
@bounds @describe @units @timescale @with_kw struct cFlowLitterfall_GSI{T1,T2} <: cFlowLitterfall
    k_shedding::T1 = 0.14 | (0.033, 0.33) | "rate of shedding" | "fraction" | "day"
    f_τ::T2 = 0.03 | (0.01, 0.10) | "contribution factor for current stressor" | "fraction" | "day"
end
#! format: on

function compute(params::cFlowLitterfall_GSI, forcing, land, helpers)
    ## unpack parameters
    @unpack_cFlowLitterfall_GSI params
    ## unpack land variables
    @unpack_nt begin
        slope_eco_stressor  ⇐ land.diagnostics
    end
    # get the shedding rates
    shedding_frac = at_most_one(at_least_zero(-slope_eco_stressor) * k_shedding) # number when negative, 0 when positive
    ## pack land variables
    @pack_nt begin
        shedding_frac ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFlowLitterfall_GSI}) = "."

@doc """

$(getModelDocString(cFlowLitterfall_GSI))


---

# Extended help

The reserve-pool exchange and leaf/root shedding this approach models are located
by pool membership (`edgesBetween`), not by naming an exact `<giver>_to_<taker>`
edge, so the same code applies unchanged whether Leaf's shedding lands in one
pool (`GSI`'s `cLitFast`) or several (`CASA`'s
`cLitLeafFast`/`cLitLeafSlow`), and whether a reserve pool exists at all: an
absent one (`CASA` has none) makes every reserve-related edge lookup
return no matches, so those terms simply contribute nothing rather than erroring
or silently mismatching the wrong edge.

*References*

*Versions*
 - 1.0 on 13.01.2020 [sbesnard]
 - 1.1 on 05.02.2021 [skoirala | @dr-ko]: changes with stressors & smoothing as well as handling the activation of leaf/root to reserve | reserve to leaf/root switches. Adjustment of total flow rates [cTau] of relevant pools
 - 1.1 on 05.02.2021 [skoirala | @dr-ko]: move code from dyna. Add table etc.
 - 1.2 on 10.09.2026 [skoirala]: edge selection generalized from exact `c_flow_named_edges.<giver>_to_<taker>` name lookups (which errored on any pool structure without a literal edge of that exact name, e.g. CASA's absent cVegReserve or its split cLitLeafFast/cLitLeafSlow in place of cLitFast) to `edgesBetween`, a giver/taker pool-membership match

*Created by*
 - ncarvalhais, sbesnard, skoirala

*Notes*
"""
cFlowLitterfall_GSI
