export cFlow_GSI

#! format: off
@bounds @describe @units @timescale @with_kw struct cFlow_GSI{T1,T2,T3,T4} <: cFlow
    slope_leaf_root_to_reserve::T1 = 0.14 | (0.033, 0.33) | "Leaf-Root to Reserve" | "fraction" | "day"
    slope_reserve_to_leaf_root::T2 = 0.14 | (0.033, 0.33) | "Reserve to Leaf-Root" | "fraction" | "day"
    k_shedding::T3 = 0.14 | (0.033, 0.33) | "rate of shedding" | "fraction" | "day"
    f_τ::T4 = 0.03 | (0.01, 0.10) | "contribution factor for current stressor" | "fraction" | "day"
end
#! format: on

function define(params::cFlow_GSI, forcing, land, helpers)
    @unpack_cFlow_GSI params
    @unpack_nt begin
        (cEco, soilW) ⇐ land.pools
        (c_giver, c_taker) ⇐ land.constants
        cEco_comps = cEco ⇐ helpers.pools.components
        ∑w_sat ⇐ land.properties
    end
    ## Instantiate variables

    # transfers
    aTrg = []
    for t_rg in c_taker
        push!(aTrg, cEco_comps[t_rg])
    end
    aSrc = []
    for s_rc in c_giver
        push!(aSrc, cEco_comps[s_rc])
    end

    # aTrg_a = Tuple(aTrg_a)
    # aSrc_b = Tuple(aSrc_a)

    # flowVar = [:reserve_to_leaf, :reserve_to_root, :leaf_to_reserve, :root_to_reserve, :k_shedding_leaf, :k_shedding_root]
    # aSrc = (:cVegReserve, :cVegReserve, :cVegLeaf, :cVegRoot, :cVegLeaf, :cVegRoot)
    # aTrg = (:cVegLeaf, :cVegRoot, :cVegReserve, :cVegReserve, :cLitFast, :cLitFast)

    aSrc = Tuple(aSrc)
    aTrg = Tuple(aTrg)

    # @show aSrc, aSrc_b
    # @show aTrg, aTrg_a
    c_flow_A_vec_ind = (reserve_to_leaf=findall((aSrc .== :cVegReserve) .* (aTrg .== :cVegLeaf) .== true)[1],
        reserve_to_root=findall((aSrc .== :cVegReserve) .* (aTrg .== :cVegRoot) .== true)[1],
        leaf_to_reserve=findall((aSrc .== :cVegLeaf) .* (aTrg .== :cVegReserve) .== true)[1],
        root_to_reserve=findall((aSrc .== :cVegRoot) .* (aTrg .== :cVegReserve) .== true)[1],
        k_shedding_leaf=findall((aSrc .== :cVegLeaf) .* (aTrg .== :cLitFast) .== true)[1],
        k_shedding_root=findall((aSrc .== :cVegRoot) .* (aTrg .== :cLitFast) .== true)[1],
        k_shedding_reserve=findall((aSrc .== :cVegReserve) .* (aTrg .== :cLitFast) .== true)[1])

    # tc_print(c_flow_A_vec_ind)
    c_flow_A_vec = one.(eltype(cEco).(zero([c_taker...])))

    if cEco isa SVector
        c_flow_A_vec = SVector{length(c_flow_A_vec)}(c_flow_A_vec)
    end

    eco_stressor_prev = totalS(soilW) / ∑w_sat
    slope_eco_stressor_prev = zero(eco_stressor_prev)

    @pack_nt begin
        c_flow_A_vec_ind ⇒ land.cFlow
        eco_stressor_prev ⇒ land.diagnostics
        slope_eco_stressor_prev ⇒ land.diagnostics
        c_flow_A_vec ⇒ land.diagnostics
    end

    return land
end

function adjust_pk(c_eco_k, kValue, flowValue, maxValue, zix, helpers)
    c_eco_k_f_sum = zero(eltype(c_eco_k))
    c_eco_k_sum = zero(eltype(c_eco_k))
    for ix ∈ zix
        # get max possible loss and total loss per pool
        tmp = min(c_eco_k[ix] + kValue + flowValue, maxValue)
        @rep_elem tmp ⇒ (c_eco_k, ix, :cEco)
        c_eco_k_f_sum = c_eco_k_f_sum + tmp
        # get max possible loss to litter and total loss to litter per pool
        tmp_k = at_least_zero(tmp - flowValue)
        c_eco_k_sum = c_eco_k_sum + tmp_k
    end
    return c_eco_k, c_eco_k_f_sum, c_eco_k_sum
end

function compute(params::cFlow_GSI, forcing, land, helpers)
    ## unpack parameters
    @unpack_cFlow_GSI params
    ## unpack land variables
    @unpack_nt begin
        c_flow_A_vec_ind ⇐ land.cFlow
        (c_allocation_f_soilW, c_allocation_f_soilT, c_allocation_f_cloud, eco_stressor_prev, slope_eco_stressor_prev)  ⇐ land.diagnostics
        c_eco_k ⇐ land.diagnostics
        c_flow_A_vec ⇐ land.diagnostics
    end

    # Compute sigmoid functions
    # LPJ-GSI formulation: In GSI; the stressors are smoothened per control variable. That means; gppfsoilW; fTair; and fRdiff should all have a GSI approach for 1:1 conversion. For now; the function below smoothens the combined stressors; & then calculates the slope for allocation
    # current time step before smoothing
    # attention, the stressors are to be interepreted like this: 
    
    #   high stressor (close to 1) means actually low stress
    #   low stressor (close to 0) means actually high stress
    # this is counterintuitive, but it is how the GSI formulation works

    eco_stressor = c_allocation_f_soilW * c_allocation_f_soilT * c_allocation_f_cloud

    # get the smoothened stressor based on contribution of previous steps using ARMA-like formulation
    slope_eco_stressor_now = eco_stressor - eco_stressor_prev
    
    slope_eco_stressor = (one(f_τ) - f_τ) * slope_eco_stressor_prev + f_τ * slope_eco_stressor_now

    # calculate the flow rate for exchange with reserve pools based on the slopes
    # get the flow & shedding rates
    leaf_root_to_reserve = at_most_one(at_least_zero(-slope_eco_stressor) * slope_leaf_root_to_reserve) # number when negative (increasing stress; decreasing stressor), 0 when positive
    reserve_to_leaf_root = at_most_one(at_least_zero(slope_eco_stressor) * slope_reserve_to_leaf_root) # number when positive, 0 when negative
    shedding_rate = at_most_one(at_least_zero(-slope_eco_stressor) * k_shedding) # number when negative, 0 when positive


    # set the Leaf & Root to Reserve flow rate as the same
    leaf_to_reserve = leaf_root_to_reserve # should it be divided by 2?
    root_to_reserve = leaf_root_to_reserve 
    #todo this is needed to make sure that the flow out of Leaf or root does not exceed one. was not needed in matlab version, but reaches this point often in julia, when the eco_stressor suddenly drops from 1 to near zero.
    k_shedding_leaf = min(shedding_rate, one(leaf_to_reserve) - leaf_to_reserve)
    k_shedding_root = min(shedding_rate, one(root_to_reserve) - root_to_reserve)

    # Estimate flows from reserve to leaf & root (sujan modified on
    w = zero(slope_leaf_root_to_reserve)
    if c_allocation_f_soilW + c_allocation_f_cloud !== zero(c_allocation_f_cloud)
        w = (c_allocation_f_soilW / (c_allocation_f_cloud + c_allocation_f_soilW)) # if water stressor is high, , larger fraction of reserve goes to the leaves for light acquisition
    end
    Re2L_i = reserve_to_leaf_root * w
    Re2R_i = reserve_to_leaf_root * (one(Re2L_i) - w) # if light stressor is high (=sufficient light), larger fraction of reserve goes to the root for water uptake

    # adjust the outflow rate from the flow pools
    c_eco_k, leaf_k_f_sum, leaf_k_sum = adjust_pk(c_eco_k, k_shedding_leaf, leaf_to_reserve, one(leaf_to_reserve), helpers.pools.zix.cVegLeaf, helpers)
    leaf_to_reserve_frac = safe_divide(leaf_to_reserve, leaf_k_f_sum)
    k_shedding_leaf_frac = safe_divide(leaf_k_sum, leaf_k_f_sum)

    c_eco_k, root_k_f_sum, root_k_sum = adjust_pk(c_eco_k, k_shedding_root, root_to_reserve, one(root_to_reserve), helpers.pools.zix.cVegRoot, helpers)
    root_to_reserve_frac = safe_divide(root_to_reserve, root_k_f_sum)
    k_shedding_root_frac = safe_divide(root_k_sum, root_k_f_sum)

    c_eco_k, reserve_k_f_sum, reserve_k_sum = adjust_pk(c_eco_k, zero(Re2L_i), Re2R_i + Re2L_i, one(Re2R_i), helpers.pools.zix.cVegReserve, helpers)
    reserve_to_leaf_frac = safe_divide(Re2L_i, reserve_k_f_sum)
    reserve_to_root_frac = safe_divide(Re2R_i, reserve_k_f_sum)
    k_shedding_reserve = reserve_k_sum
    k_shedding_reserve_frac = safe_divide(reserve_k_sum, reserve_k_f_sum)
    
    c_flow_A_vec = repElem(c_flow_A_vec, reserve_to_leaf_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.reserve_to_leaf)
    c_flow_A_vec = repElem(c_flow_A_vec, reserve_to_root_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.reserve_to_root)
    c_flow_A_vec = repElem(c_flow_A_vec, leaf_to_reserve_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.leaf_to_reserve)
    c_flow_A_vec = repElem(c_flow_A_vec, root_to_reserve_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.root_to_reserve)
    c_flow_A_vec = repElem(c_flow_A_vec, k_shedding_leaf_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.k_shedding_leaf)
    c_flow_A_vec = repElem(c_flow_A_vec, k_shedding_root_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.k_shedding_root)
    c_flow_A_vec = repElem(c_flow_A_vec, k_shedding_reserve_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.k_shedding_reserve)

    # store the varibles in diagnostic structure
    reserve_to_leaf = Re2L_i
    reserve_to_root = Re2R_i
    
    eco_stressor_prev = eco_stressor
    slope_eco_stressor_prev = slope_eco_stressor

    ## pack land variables
    @pack_nt begin
        (
            leaf_to_reserve, leaf_to_reserve_frac, 
            root_to_reserve, root_to_reserve_frac, 
            reserve_to_leaf, reserve_to_leaf_frac, 
            reserve_to_root, reserve_to_root_frac,
            k_shedding, 
            k_shedding_leaf, k_shedding_leaf_frac, leaf_k_sum, 
            k_shedding_root, k_shedding_root_frac, root_k_sum, 
            k_shedding_reserve, k_shedding_reserve_frac, root_k_sum, 
            eco_stressor, slope_eco_stressor, 
            eco_stressor_prev, slope_eco_stressor_prev, 
            c_eco_k
        ) ⇒ land.diagnostics
        c_flow_A_vec ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFlow_GSI}) = "Carbon transfer rates between pools based on the GSI approach, using stressors such as soil moisture, temperature, and light."

@doc """

$(getModelDocString(cFlow_GSI))


---

# Extended help

*References*

*Versions*
 - 1.0 on 13.01.2020 [sbesnard]
 - 1.1 on 05.02.2021 [skoirala | @dr-ko]: changes with stressors & smoothing as well as handling the activation of leaf/root to reserve | reserve to leaf/root switches. Adjustment of total flow rates [cTau] of relevant pools  
 - 1.1 on 05.02.2021 [skoirala | @dr-ko]: move code from dyna. Add table etc.  

*Created by*
 - ncarvalhais, sbesnard, skoirala

*Notes*
"""
cFlow_GSI
