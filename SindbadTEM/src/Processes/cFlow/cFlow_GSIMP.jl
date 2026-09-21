export cFlow_GSIMP

struct cFlow_GSIMP <: cFlow end

function define(params::cFlow_GSIMP, forcing, land, helpers)
    return land
end

function compute(params::cFlow_GSIMP, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        (c_giver, c_taker) ⇐ land.cCycleBase
        (
            shedding_rate,
            leaf_to_reserve, #leaf_to_reserve_frac, 
            root_to_reserve, #root_to_reserve_frac, 
            reserve_to_leaf, #reserve_to_leaf_frac, 
            reserve_to_root, #reserve_to_root_frac, 
        )  ⇐ land.diagnostics
        c_eco_k ⇐ land.diagnostics
        c_flow_A_vec ⇐ land.diagnostics
    end
    zix_cVegLeaf = helpers.pools.zix.cVegLeaf
    zix_cVegRoot = helpers.pools.zix.cVegRoot
    zix_cVegReserve = helpers.pools.zix.cVegReserve
    zix_cLit = helpers.pools.zix.cLit

    has_leaf_to_reserve = any(c_giver[f] ∈ zix_cVegLeaf && c_taker[f] ∈ zix_cVegReserve for f ∈ eachindex(c_giver, c_taker))
    has_root_to_reserve = any(c_giver[f] ∈ zix_cVegRoot && c_taker[f] ∈ zix_cVegReserve for f ∈ eachindex(c_giver, c_taker))
    has_reserve_to_leaf = any(c_giver[f] ∈ zix_cVegReserve && c_taker[f] ∈ zix_cVegLeaf for f ∈ eachindex(c_giver, c_taker))
    has_reserve_to_root = any(c_giver[f] ∈ zix_cVegReserve && c_taker[f] ∈ zix_cVegRoot for f ∈ eachindex(c_giver, c_taker))
    leaf_to_reserve = has_leaf_to_reserve ? leaf_root_to_reserve : zero(leaf_root_to_reserve)
    root_to_reserve = has_root_to_reserve ? leaf_root_to_reserve : zero(leaf_root_to_reserve)
    reserve_to_leaf = has_reserve_to_leaf ? reserve_to_leaf : zero(reserve_to_leaf)
    reserve_to_root = has_reserve_to_root ? reserve_to_root : zero(reserve_to_root)
    
    # make sure that the flow out of leaf or root does not exceed one. 
    # prioritize storage
    k_shedding_leaf = min(shedding_rate, one(leaf_to_reserve) - leaf_to_reserve)
    k_shedding_root = min(shedding_rate, one(root_to_reserve) - root_to_reserve)

    # adjust the outflow rate from the flow pools
    c_eco_k, leaf_k_f_sum, leaf_k_sum = adjust_pk(c_eco_k, k_shedding_leaf, leaf_to_reserve, one(leaf_to_reserve), helpers.pools.zix.cVegLeaf, helpers)
    leaf_to_reserve_frac = safe_divide(leaf_to_reserve * length(zix_cVegLeaf), leaf_k_f_sum)
    k_shedding_leaf_frac = safe_divide(leaf_k_sum, leaf_k_f_sum)

    c_eco_k, root_k_f_sum, root_k_sum = adjust_pk(c_eco_k, k_shedding_root, root_to_reserve, one(root_to_reserve), helpers.pools.zix.cVegRoot, helpers)
    root_to_reserve_frac = safe_divide(root_to_reserve * length(zix_cVegRoot), root_k_f_sum)
    k_shedding_root_frac = safe_divide(root_k_sum, root_k_f_sum)

    c_eco_k, reserve_k_f_sum, reserve_k_sum = adjust_pk(c_eco_k, zero(reserve_to_leaf), reserve_to_root + reserve_to_leaf, one(reserve_to_root), helpers.pools.zix.cVegReserve, helpers)
    reserve_to_leaf_frac = safe_divide(reserve_to_leaf * length(zix_cVegReserve), reserve_k_f_sum)
    reserve_to_root_frac = safe_divide(reserve_to_root * length(zix_cVegReserve), reserve_k_f_sum)
    k_shedding_reserve = reserve_k_sum
    k_shedding_reserve_frac = safe_divide(reserve_k_sum, reserve_k_f_sum)
    
    # adjust A accordingly
    for flow ∈ edgesBetween(c_giver, c_taker, zix_cVegReserve, zix_cVegLeaf)
        giver = c_giver[flow]
        c_flow_A_vec = repElem(c_flow_A_vec, safe_divide(reserve_to_leaf, c_eco_k[giver]), flow)
    end
    for flow ∈ edgesBetween(c_giver, c_taker, zix_cVegReserve, zix_cVegRoot)
        giver = c_giver[flow]
        c_flow_A_vec = repElem(c_flow_A_vec, safe_divide(reserve_to_root, c_eco_k[giver]), flow)
    end
    for flow ∈ edgesBetween(c_giver, c_taker, zix_cVegLeaf, zix_cVegReserve)
        giver = c_giver[flow]
        c_flow_A_vec = repElem(c_flow_A_vec, safe_divide(leaf_to_reserve, c_eco_k[giver]), flow)
    end
    for flow ∈ edgesBetween(c_giver, c_taker, zix_cVegRoot, zix_cVegReserve)
        giver = c_giver[flow]
        c_flow_A_vec = repElem(c_flow_A_vec, safe_divide(root_to_reserve, c_eco_k[giver]), flow)
    end
    for flow ∈ edgesBetween(c_giver, c_taker, zix_cVegLeaf, zix_cLit)
        giver = c_giver[flow]
        c_flow_A_vec = repElem(c_flow_A_vec, safe_divide(at_least_zero(c_eco_k[giver] - leaf_to_reserve), c_eco_k[giver]), flow)
    end
    for flow ∈ edgesBetween(c_giver, c_taker, zix_cVegRoot, zix_cLit)
        giver = c_giver[flow]
        c_flow_A_vec = repElem(c_flow_A_vec, safe_divide(at_least_zero(c_eco_k[giver] - root_to_reserve), c_eco_k[giver]), flow)
    end
    for flow ∈ edgesBetween(c_giver, c_taker, zix_cVegReserve, zix_cLit)
        giver = c_giver[flow]
        c_flow_A_vec = repElem(c_flow_A_vec, safe_divide(at_least_zero(c_eco_k[giver] - Re2L_i - Re2R_i), c_eco_k[giver]), flow)
    end

    ## pack land variables
    @pack_nt begin
        (
            leaf_to_reserve_frac, 
            root_to_reserve_frac, 
            reserve_to_leaf, reserve_to_leaf_frac, 
            reserve_to_root, reserve_to_root_frac,
            k_shedding_leaf, k_shedding_leaf_frac, leaf_k_sum, 
            k_shedding_root, k_shedding_root_frac, root_k_sum, 
            k_shedding_reserve, k_shedding_reserve_frac, 
            c_eco_k
        ) ⇒ land.diagnostics
        c_flow_A_vec ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFlow_GSIMP}) = "Carbon transfer rates related to vegetation pools."

@doc """

$(getModelDocString(cFlow_GSIMP))


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
GSI Multi-Pools
Adjust GSI turnover and flow fractions per giver pool, applying reserve exchange only for existing edges
and routing the remaining vegetation turnover to litter so total turnover is fully partitioned.
GSI flow adjustments:
 - Add shedding and reserve-transfer rates to the corresponding vegetation turnover rates.
 - Apply reserve-transfer turnover only when the corresponding reserve edge exists.
 - Normalize flow fractions per giver pool using its own total turnover rate.
 - Route non-reserve vegetation turnover to litter and reserve turnover to leaf/root/litter.
 - Preserve full turnover partitioning so outgoing flow fractions account for the giver's turnover.
"""
cFlow_GSIMP
