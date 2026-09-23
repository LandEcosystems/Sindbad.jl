export cFlowStress_GSI

#! format: off
@bounds @describe @units @timescale @with_kw struct cFlowStress_GSI{T1} <: cFlowStress
    f_τ::T1 = 0.03 | (0.01, 0.10) | "contribution factor for current stressor" | "fraction" | "day"
end
#! format: on

function define(params::cFlowStress_GSI, forcing, land, helpers)
    @unpack_cFlowStress_GSI params
    @unpack_nt begin
        soilW ⇐ land.pools
        ∑w_sat ⇐ land.properties
    end
    ## Instantiate variables

    # The transfer topology and the flow vector itself both belong to cCycleBase,
    # which resolves them once. This approach only needs its own stressor state; it
    # finds the flows it writes in compute through edgesBetween, a giver/taker
    # pool-membership match.
    eco_stressor_prev = totalS(soilW) / ∑w_sat
    slope_eco_stressor_prev = zero(eco_stressor_prev)

    @pack_nt begin
        (eco_stressor_prev, slope_eco_stressor_prev) ⇒ land.diagnostics
    end

    return land
end

function compute(params::cFlowStress_GSI, forcing, land, helpers)
    ## unpack parameters
    @unpack_cFlowStress_GSI params
    ## unpack land variables
    @unpack_nt begin
        (c_allocation_f_soilW, c_allocation_f_soilT, c_allocation_f_cloud, 
            eco_stressor_prev, slope_eco_stressor_prev)  ⇐ land.diagnostics
    end
    # Compute sigmoid functions
    # LPJ-GSI formulation: In GSI; the stressors are smoothened per control variable. 
    # That means; gppfsoilW; fTair; and fRdiff should all have a GSI approach for 1:1 
    # conversion. For now; the function below smoothens the combined stressors; & then 
    # calculates the slope for allocation
    # current time step before smoothing
    # attention, the stressors are to be interepreted like this: 
    #   high stressor (close to 1) means actually low stress
    #   low stressor (close to 0) means actually high stress
    # this is counterintuitive, but it is how the GSI formulation works
    eco_stressor = c_allocation_f_soilW * c_allocation_f_soilT * c_allocation_f_cloud

    # get the smoothened stressor based on contribution of previous steps using ARMA-like formulation
    slope_eco_stressor_now = eco_stressor - eco_stressor_prev
    slope_eco_stressor = (one(f_τ) - f_τ) * slope_eco_stressor_prev + f_τ * slope_eco_stressor_now

    # store them for next time
    eco_stressor_prev = eco_stressor
    slope_eco_stressor_prev = slope_eco_stressor

    ## pack land variables
    @pack_nt begin
        (
            eco_stressor, slope_eco_stressor, 
            eco_stressor_prev, slope_eco_stressor_prev, 
        ) ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFlowStress_GSI}) = "Carbon transfer rates between pools based on the GSI approach, using stressors such as soil moisture, temperature, and light."

@doc """

$(getModelDocString(cFlowStress_GSI))


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
cFlowStress_GSI
