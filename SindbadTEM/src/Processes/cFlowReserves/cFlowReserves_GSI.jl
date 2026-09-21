export cFlowReserves_GSI

#! format: off
@bounds @describe @units @timescale @with_kw struct cFlowReserves_GSI{T1,T2,T3} <: cFlow
    slope_leaf_root_to_reserve::T1 = 0.14 | (0.033, 0.33) | "Leaf-Root to Reserve" | "fraction" | "day"
    slope_reserve_to_leaf_root::T2 = 0.14 | (0.033, 0.33) | "Reserve to Leaf-Root" | "fraction" | "day"
    f_τ::T3 = 0.03 | (0.01, 0.10) | "contribution factor for current stressor" | "fraction" | "day"
end
#! format: on

function compute(params::cFlowReserves_GSI, forcing, land, helpers)
    ## unpack parameters
    @unpack_cFlowReserves_GSI params
    ## unpack land variables
    @unpack_nt begin
        (c_allocation_f_soilW, c_allocation_f_soilT, c_allocation_f_cloud, 
            slope_eco_stressor)  ⇐ land.diagnostics
    end

    # calculate the flow rate for exchange with reserve pools based on the slopes
    # get the flow & shedding rates
    leaf_root_to_reserve = at_most_one(at_least_zero(-slope_eco_stressor) * slope_leaf_root_to_reserve) # number when negative (increasing stress; decreasing stressor), 0 when positive
    reserve_to_leaf_root = at_most_one(at_least_zero(slope_eco_stressor) * slope_reserve_to_leaf_root) # number when positive, 0 when negative

    # set the Leaf & Root to Reserve flow rate as the same
    leaf_to_reserve = leaf_root_to_reserve # should it be divided by 2?
    root_to_reserve = leaf_root_to_reserve 

    # Estimate flows from reserve to leaf & root (sujan modified on
    w = zero(slope_leaf_root_to_reserve)
    if c_allocation_f_soilW + c_allocation_f_cloud !== zero(c_allocation_f_cloud)
        w = (c_allocation_f_soilW / (c_allocation_f_cloud + c_allocation_f_soilW)) # if water stressor is high, , larger fraction of reserve goes to the leaves for light acquisition
    end
    Re2L_i = reserve_to_leaf_root * w
    Re2R_i = reserve_to_leaf_root * (one(Re2L_i) - w) # if light stressor is high (=sufficient light), larger fraction of reserve goes to the root for water uptake

    # store the varibles in diagnostic structure
    reserve_to_leaf = Re2L_i
    reserve_to_root = Re2R_i
    
    ## pack land variables
    @pack_nt begin
        (
            leaf_to_reserve, #leaf_to_reserve_frac, 
            root_to_reserve, #root_to_reserve_frac, 
            reserve_to_leaf, #reserve_to_leaf_frac, 
            reserve_to_root, #reserve_to_root_frac,
        ) ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFlowReserves_GSI}) = "Carbon transfer rates between pools based on the GSI approach, using stressors such as soil moisture, temperature, and light."

@doc """

$(getModelDocString(cFlowReserves_GSI))


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
cFlowReserves_GSI
