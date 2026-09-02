export cFlow_GSI_subdaily

#! format: off
@bounds @describe @units @timescale @with_kw struct cFlow_GSI_subdaily{T1,T2,T3,T4,T5} <: cFlow
	slope_leaf_root_to_reserve::T1 = 0.1 | (0.01, 0.99) | "Leaf-Root to Reserve" | "fraction" | ""
    slope_reserve_to_leaf_root::T2 = 0.1 | (0.01, 0.99) | "Reserve to Leaf-Root" | "fraction" | ""
    k_shedding::T3 = 0.1 | (0.01, 0.99) | "rate of shedding" | "fraction" | ""
    f_τ::T4 = 0.1 | (0.01, 0.99) | "contribution factor for current stressor" | "fraction" | "day"
	f_rg_pot_threshold::T5 = 0.01 | (-Inf, Inf) | "threshold for f_rg_pot" | "fraction" | ""
end
#! format: on

function define(params::cFlow_GSI_subdaily, forcing, land, helpers)

	@unpack_cFlow_GSI_subdaily params
    @unpack_nt begin
        (cEco, soilW) ⇐ land.pools
        (c_giver, c_taker) ⇐ land.constants
        cEco_comps = cEco ⇐ helpers.pools.components
        ∑w_sat ⇐ land.properties
        
        c_eco_k ⇐ land.diagnostics
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

    # # @debug aSrc, aSrc_b
    # # @debug aTrg, aTrg_a
    c_flow_A_vec_ind = (reserve_to_leaf=findall((aSrc .== :cVegReserve) .* (aTrg .== :cVegLeaf) .== true)[1],
        reserve_to_root=findall((aSrc .== :cVegReserve) .* (aTrg .== :cVegRoot) .== true)[1],
        leaf_to_reserve=findall((aSrc .== :cVegLeaf) .* (aTrg .== :cVegReserve) .== true)[1],
        root_to_reserve=findall((aSrc .== :cVegRoot) .* (aTrg .== :cVegReserve) .== true)[1],
        k_shedding_leaf=findall((aSrc .== :cVegLeaf) .* (aTrg .== :cLitFast) .== true)[1],
        k_shedding_root=findall((aSrc .== :cVegRoot) .* (aTrg .== :cLitFast) .== true)[1])

    # tcPrint(c_flow_A_vec_ind)
    c_flow_A_vec = one.(eltype(cEco).(zero([c_taker...])))

    if cEco isa SVector
        c_flow_A_vec = SVector{length(c_flow_A_vec)}(c_flow_A_vec)
    end

    eco_stressor_prev = totalS(soilW) / ∑w_sat

    c_eco_k_rep = zero(cEco)

    Re2L_i = zero(f_τ)
    Re2R_i = zero(f_τ)


    @pack_nt begin
        c_flow_A_vec_ind ⇒ land.cFlow
        eco_stressor_prev ⇒ land.diagnostics
        c_flow_A_vec ⇒ land.diagnostics
        c_eco_k_rep ⇒ land.diagnostics
        (Re2L_i, Re2R_i) ⇒ land.diagnostics
    end

	return land
end

function adjust_pk_subdaily(c_eco_k, kValue, flowValue, maxValue, zix, helpers)
    c_eco_k_f_sum = zero(eltype(c_eco_k))
    for ix ∈ zix
        # # @debug ix, c_eco_k[ix]
        tmp = min(c_eco_k[ix] + kValue + flowValue, maxValue)
        @rep_elem tmp ⇒ (c_eco_k, ix, :cEco)
        c_eco_k_f_sum = c_eco_k_f_sum + tmp
    end
    return c_eco_k, c_eco_k_f_sum
end


function compute(params::cFlow_GSI_subdaily, forcing, land, helpers)
	## Automatically generated sample code for basis. Modify, correct, and use. define, precompute, and update methods can use similar coding when needed. When not, they can simply be deleted. 
	@unpack_cFlow_GSI_subdaily params # unpack the model parameters
	## unpack NT forcing
	# @unpack_nt f_variable ⇐ forcing

    @unpack_nt begin
        c_flow_A_vec_ind ⇐ land.cFlow
        (c_allocation_f_soilW, c_allocation_f_soilT, c_allocation_f_cloud, eco_stressor_prev)  ⇐ land.diagnostics
        c_eco_k ⇐ land.diagnostics
        c_eco_k_rep ⇐ land.diagnostics
        c_flow_A_vec ⇐ land.diagnostics
        (Re2L_i, Re2R_i) ⇐ land.diagnostics

		f_rg_pot ⇐ forcing
    end

    for ix ∈ eachindex(c_eco_k_rep)
        @rep_elem c_eco_k[ix] ⇒ (c_eco_k_rep, ix, :cEco)
    end

    # Compute sigmoid functions
    # LPJ-GSI formulation: In GSI; the stressors are smoothened per control variable. That means; gppfsoilW; fTair; and fRdiff should all have a GSI approach for 1:1 conversion. For now; the function below smoothens the combined stressors; & then calculates the slope for allocation
    # current time step before smoothing
    eco_stressor_now = c_allocation_f_soilW * c_allocation_f_soilT * c_allocation_f_cloud

	# mask the night
	if f_rg_pot < f_rg_pot_threshold
		eco_stressor_now = eco_stressor_prev
        # @show f_rg_pot
	else
		eco_stressor_now = c_allocation_f_soilW * c_allocation_f_soilT * c_allocation_f_cloud
	end
    
    # get the smoothened stressor based on contribution of previous steps using ARMA-like formulation
    eco_stressor = (one(f_τ) - f_τ) * eco_stressor_prev + f_τ * eco_stressor_now
    # @debug eco_stressor, f_τ
    slope_eco_stressor = eco_stressor - eco_stressor_prev
    # @debug "calc shedding rate" slope_eco_stressor, k_shedding
    # @debug slope_leaf_root_to_reserve, slope_reserve_to_leaf_root

    # calculate the flow rate for exchange with reserve pools based on the slopes
    # get the flow & shedding rates
    leaf_root_to_reserve = minOne(at_least_zero(-slope_eco_stressor) * slope_leaf_root_to_reserve) # * (cVeg_growth < z_zero)
    reserve_to_leaf_root = minOne(at_least_zero(slope_eco_stressor) * slope_reserve_to_leaf_root) # * (cVeg_growth > 0.0)
    shedding_rate = minOne(at_least_zero(-slope_eco_stressor) * k_shedding)

    # @debug leaf_root_to_reserve, reserve_to_leaf_root, shedding_rate

    # set the Leaf & Root to Reserve flow rate as the same
    leaf_to_reserve = leaf_root_to_reserve # should it be divided by 2?
    root_to_reserve = leaf_root_to_reserve
    #todo this is needed to make sure that the flow out of Leaf or root does not exceed one. was not needed in matlab version, but reaches this point often in julia, when the eco_stressor suddenly drops from 1 to near zero.
    # @debug shedding_rate
    k_shedding_leaf = min(shedding_rate, one(leaf_to_reserve) - leaf_to_reserve)
    k_shedding_root = min(shedding_rate, one(root_to_reserve) - root_to_reserve)

    # Estimate flows from reserve to leaf & root (sujan modified on
    Re2L_i = zero(slope_leaf_root_to_reserve)
    if c_allocation_f_soilW + c_allocation_f_cloud !== Re2L_i
        Re2L_i = reserve_to_leaf_root * (c_allocation_f_soilW / (c_allocation_f_cloud + c_allocation_f_soilW)) # if water stressor is high, , larger fraction of reserve goes to the leaves for light acquisition
    end
    Re2R_i = reserve_to_leaf_root * (one(Re2L_i) - Re2L_i) # if light stressor is high (=sufficient light), larger fraction of reserve goes to the root for water uptake

    # adjust the outflow rate from the flow pools
    # @debug "1" c_eco_k
    # @debug k_shedding_leaf, leaf_to_reserve
    c_eco_k, c_eco_k_f_sum = adjust_pk_subdaily(c_eco_k, k_shedding_leaf, leaf_to_reserve, one(leaf_to_reserve), helpers.pools.zix.cVegLeaf, helpers)
    leaf_to_reserve_frac = getFrac(leaf_to_reserve, c_eco_k_f_sum)
    k_shedding_leaf_frac = getFrac(k_shedding_leaf, c_eco_k_f_sum)

    # @debug "2" c_eco_k

    c_eco_k, c_eco_k_f_sum = adjust_pk_subdaily(c_eco_k, k_shedding_root, root_to_reserve, one(root_to_reserve), helpers.pools.zix.cVegRoot, helpers)
    root_to_reserve_frac = getFrac(root_to_reserve, c_eco_k_f_sum)
    k_shedding_root_frac = getFrac(k_shedding_root, c_eco_k_f_sum)

    # @debug "3" c_eco_k

    c_eco_k, c_eco_k_f_sum = adjust_pk_subdaily(c_eco_k, Re2L_i, Re2R_i, one(Re2R_i), helpers.pools.zix.cVegReserve, helpers)
    reserve_to_leaf_frac = getFrac(Re2L_i, c_eco_k_f_sum)
    reserve_to_root_frac = getFrac(Re2R_i, c_eco_k_f_sum)

    c_flow_A_vec = repElem(c_flow_A_vec, reserve_to_leaf_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.reserve_to_leaf)
    c_flow_A_vec = repElem(c_flow_A_vec, reserve_to_root_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.reserve_to_root)
    c_flow_A_vec = repElem(c_flow_A_vec, leaf_to_reserve_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.leaf_to_reserve)
    c_flow_A_vec = repElem(c_flow_A_vec, root_to_reserve_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.root_to_reserve)
    c_flow_A_vec = repElem(c_flow_A_vec, k_shedding_leaf_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.k_shedding_leaf)
    c_flow_A_vec = repElem(c_flow_A_vec, k_shedding_root_frac, c_flow_A_vec, c_flow_A_vec, c_flow_A_vec_ind.k_shedding_root)

    # store the varibles in diagnostic structure
    leaf_to_reserve = leaf_root_to_reserve # should it be divided by 2?
    k_shedding_leaf = shedding_rate
    k_shedding_root = shedding_rate
    reserve_to_leaf = reserve_to_leaf_frac
    reserve_to_root = reserve_to_root_frac
    leaf_to_reserve_frac = leaf_to_reserve_frac # should it be divided by 2?

    eco_stressor_prev = eco_stressor
    # @debug c_eco_k

    ## pack land variables
    @pack_nt begin
        (leaf_to_reserve, leaf_to_reserve_frac, root_to_reserve, root_to_reserve_frac, reserve_to_leaf, reserve_to_leaf_frac, reserve_to_root, reserve_to_root_frac, eco_stressor, k_shedding_leaf, k_shedding_leaf_frac, k_shedding_root, k_shedding_root_frac, slope_eco_stressor, eco_stressor_prev, c_eco_k) ⇒ land.diagnostics
        c_flow_A_vec ⇒ land.diagnostics
        c_eco_k_rep ⇒ land.diagnostics
        (Re2L_i, Re2R_i) ⇒ land.diagnostics
    end

	return land
end


purpose(::Type{cFlow_GSI_subdaily}) = "Computes subdaily transfers between carbon pools based on the GSI method."

@doc """

$(getModelDocString(cFlow_GSI_subdaily))

---

# Extended help

Designed for hourly simulations, with reserve-to-leaf, reserve-to-root, leaf-to-reserve, root-to-reserve, and shedding flows adjusted from the smoothed GSI ecosystem stressor.

*References*

*Versions*
 - 1.0 on 09.05.2025 [xshan]

*Created by*
 - xshan
"""
cFlow_GSI_subdaily

