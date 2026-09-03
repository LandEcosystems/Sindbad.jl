export cCycle_CASA, spin_cCycle_CASA

struct cCycle_CASA <: cCycle end

function define(params::cCycle_CASA, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools
    ## Instantiate variables
    c_eco_efflux = zero(cEco) #sujan moved from get states
    c_eco_influx = zero(cEco)
    c_eco_flow = zero(cEco)

    ## pack land variables
    @pack_nt (c_eco_efflux, c_eco_influx, c_eco_flow) ⇒ land.cCycle
    return land
end

function compute(params::cCycle_CASA, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        (c_eco_efflux, c_eco_influx, c_eco_flow) ⇐ land.cCycle
        (c_eco_efflux, c_eco_flow, c_eco_influx, c_eco_out, c_eco_npp) ⇐ land.fluxes
        (cEco, cVeg) ⇐ land.pools
        gpp ⇐ land.fluxes
        (c_eco_k, c_allocation) ⇐ land.diagnostics
        (p_E_vec, p_F_vec, p_giver, p_taker) ⇐ land.cFlow
        c_flow_order ⇐ land.constants
        c_eco_τ ⇐ land.diagnostics
    end
    # NUMBER OF TIME STEPS PER YEAR
    ## these all need to be zeros maybe is taken care automatically
    c_eco_efflux[!helpers.pools.flags.cVeg] = 0.0
    ## compute losses
    c_eco_out = min.(cEco, cEco * c_eco_k)
    ## gains to vegetation
    zix = helpers.pools.zix.cVeg
    c_eco_npp = gpp .* c_allocation[zix] .- c_eco_efflux[zix]
    c_eco_influx[zix] .= c_eco_npp
    ## flows & losses
    # @nc; if flux order does not matter; remove.
    for jix ∈ eachindex(c_flow_order)
        c_taker = p_taker[c_flow_order[jix]]
        c_giver = p_giver[c_flow_order[jix]]
        flow_tmp = c_eco_out[c_giver] * p_F_vec(c_taker, c_giver)
        c_eco_flow[c_taker] = c_eco_flow[c_taker] + flow_tmp * p_E_vec(c_taker, c_giver)
        c_eco_efflux[c_giver] = c_eco_efflux[c_giver] + flow_tmp * (1.0 - p_E_vec(c_taker, c_giver))
    end
    ## balance
    cEco = cEco + c_eco_flow + c_eco_influx - c_eco_out
    ## compute RA & RH
    hetero_respiration = sum(c_eco_efflux[!helpers.pools.flags.cVeg]) #sujan added 1 to sum along all pools
    auto_respiration = sum(c_eco_efflux[helpers.pools.flags.cVeg]) #sujan added 1 to sum along all pools
    eco_respiration = hetero_respiration + auto_respiration
    c_eco_npp = sum(c_eco_npp)
    nee = eco_respiration - gpp

    ## pack land variables
    @pack_nt begin
        (nee, c_eco_npp, auto_respiration, eco_respiration, hetero_respiration) ⇒ land.fluxes
        (c_eco_efflux, c_eco_flow, c_eco_influx, c_eco_out, c_eco_npp) ⇒ land.states
    end
    return land
end

purpose(::Type{cCycle_CASA}) = "Carbon cycle wtih components based on the CASA approach."

@doc """

$(getModelDocString(cCycle_CASA))

---

# Extended help

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].
 - Potter, C., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003).  Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data & ecosystem  modeling 1982–1998. Global & Planetary Change, 39[3-4], 201-213.
 - Potter; C. S.; Randerson; J. T.; Field; C. B.; Matson; P. A.; Vitousek; P. M.; Mooney; H. A.  & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global  satellite & surface data. Global Biogeochemical Cycles, 7[4], 811-841.

*Versions*
 - 1.0 on 28.02.2020 [sbesnard]  

*Created by*
 - ncarvalhais
"""
cCycle_CASA

"""
Solve the steady state of the cCycle for the CASA model based on recurrent. Returns the model C pools in equilibrium

# Inputs:

  - land.cFlow.p_E_vec: effect of soil & vegetation on transfer efficiency between pools
  - land.cFlow.p_giver: c_giver pool array
  - land.cFlow.p_taker: c_taker pool array
  - land.fluxes.gpp: values for gross primary productivity
  - land.history.p_cTau_k: Turn over times carbon pools

# Outputs:

  - land.pools.cEco: states of the different carbon pools

# Modifies:

# Extended help

# References:

  - Not published but similar to: Lardy, R., Bellocchi, G., & Soussana, J. F. (2011). A new method to determine soil organic carbon equilibrium.  Environmental modelling & software, 26[12], 1759-1763.

# Versions:

  - 1.0 on 01.05.2018
  - 1.1 on 29.10.2019: fixed the wrong removal of a dimension by squeeze on  Bt & At when nPix == 1 [single point simulation]

# Created by

  - ncarvalhais
  - skoirala | @dr-ko

# Notes:

  - for model structures that loop the carbon cycle between pools this is  merely a rough approximation [the solution does not really work]
  - the input datasets [f, fe, fx, s, d] have to have a full year (or cycle  of years) that will be used as the recycling dataset for the  determination of C pools at equilibrium
"""
function spin_cCycle_CASA(forcing, land, helpers, NI2E)
    @unpack_nt f_airT ⇐ forcing

    @unpack_nt begin
        cEco ⇐ land.pools
        (c_allocation, cEco, p_autoRespiration_km4su, p_cFlow_A, p_cTau_k) ⇐ land.history
        gpp ⇐ land.fluxes
        (p_giver, p_taker) ⇐ land.cFlow
        YG ⇐ land.diagnostics
        (z_zero, o_one) ⇐ land.constants
    end

    ## calculate variables
    # START fCt - final time series of pools
    fCt = cEco
    sCt = cEco
    # updated states / diagnostics & fluxessT = s
    dT = d
    fxT = fx
    # helpers
    nPix = 1
    nTix = info.helpers.sizes.nTix
    # matrices for the calculations
    cLossRate = zero(cEco)
    cGain = cLossRate
    cLoxxRate = cLossRate
    ## some debugging
    # if!isfield(land.history, "p_autoRespiration_km4su")
    # p_autoRespiration_km4su = cLossRate
    # end
    # if!isfield(p, "raAct")
    # p.autoRespiration.YG = 1.0
    # elseif!isfield(land.raAct, "YG")
    # p.autoRespiration.YG = 1.0
    # end
    ## ORDER OF CALCULATIONS [1 to the end of pools]
    zixVec = helpers.pools.zix.cEco
    # BUT, we sort from left to right [veg to litter to soil] & prioritize
    # without loops
    kmoves = 0
    zixVecOrder = zixVec
    zixVecOrder_veg = []
    zixVecOrder_nonVeg = []
    for zix ∈ zixVec
        move = false
        ndxGainFrom = find(p_taker == zix)
        c_lose_to_zix = p_taker[p_giver==zix]
        for ii ∈ eachindex(ndxGainFrom)
            c_giver = p_giver[ndxGainFrom[ii]]
            if any(c_giver == c_lose_to_zix)
                move = true
                kmoves = kmoves + 1
            end
        end
        if move
            zixVecOrder[zixVecOrder==zix] = []
            zixVecOrder = [zixVecOrder zix]
        end
    end
    for zv ∈ zixVecOrder
        if any(zv == helpers.pools.zix.cVeg)
            zixVecOrder_veg = [zixVecOrder_veg zv]
        else
            zixVecOrder_nonVeg = [zixVecOrder_nonVeg zv]
        end
    end
    zixVecOrder = [zixVecOrder_veg zixVecOrder_nonVeg]
    # zixVecOrder = [2 1 3 4 5]
    # if kmoves > 0
    # zixVecOrder = [zixVecOrder zixVecOrder[end-kmoves+1:end]]
    # end
    ## solve it for each pool individually
    for zix ∈ zixVecOrder
        # general k loss
        cLossRate[zix, :] = clamp_zero_one(p_cTau_k[zix]) #1 replaced by 0.9999 to avoid having denom in line 140 > 0.
        # so that pools are not NaN
        if any(zix == helpers.pools.zix.cVeg)
            # additional losses [RA] in veg pools
            cLoxxRate[zix, :] = min(1.0 - p_autoRespiration_km4su[zix], 1)
            # gains in veg pools
            gppShp = reshape(gpp, nPix, 1, nTix) # could be fxT?
            cGain[zix, :] = c_allocation[zix, :] * gppShp * YG
        end
        if any(zix == p_taker)
            # no additional gains from outside
            if !any(zix == helpers.pools.zix.cVeg)
                cLoxxRate[zix, :] = 1.0
            end
            # gains from other carbon pools
            ndxGainFrom = find(p_taker == zix)
            for ii ∈ eachindex(ndxGainFrom)
                c_taker = p_taker[ndxGainFrom[ii]] # @nc : c_taker always has to be the same as zix c_giver = p_giver[ndxGainFrom[ii]]
                denom = (1.0 - cLossRate[c_giver, :])
                adjustGain = p_cFlow_A[c_taker, c_giver, :]
                adjustGain3D = reshape(adjustGain, nPix, 1, nTix)
                cGain[c_taker, :] =
                    cGain[c_taker, :] +
                    (fCt[c_giver, :] / denom) * cLossRate[c_giver, :] * adjustGain3D
            end
        end
        ## GET THE POOLS GAINS [Gt] AND LOSSES [Lt]
        # CALCULATE At = 1 - Lt
        At = squeeze((1.0 - cLossRate[zix, :]) * cLoxxRate[zix, :])
        #sujan 29.10.2019: the squeeze removes the first dimension while
        #running for a single point when nPix == 1
        if size(cLossRate, 1) == 1
            # At = At"; # commented out for julia compilation. make sure it works.
            # Bt = squeeze(cGain[zix, :])" * At; # commented out for julia compilation. make sure it works.
        else
            Bt = squeeze(cGain[zix, :]) * At
        end
        #sujan end squeeze fix
        # CARBON AT THE END FOR THE FIRST SPINUP PHASE; npp IN EQUILIBRIUM
        Co = cEco[zix]
        # THE NEXT LINES REPRESENT THE ANALYTICAL SOLUTION FOR THE SPIN UP
        # EXCEPT FOR THE LAST 3 POOLS: SOIL MICROBIAL; SLOW AND OLD. IN THIS
        # CASE SIGNIFICANT APPROXIMATION IS CALCULATED [CHECK NOTEBOOKS].
        piA1 = (prod(At, 2))^(NI2E)
        At2 = [At ones(size(At, 1), 1)]
        sumB_piA = NaN(size(f_airT))
        for ii ∈ 1:nTix
            sumB_piA[ii] = Bt[ii] * prod(At2[(ii+1):(nTix+1)], 2)
        end
        sumB_piA = sum(sumB_piA)
        T2 = 0:1:(NI2E-1)
        piA2 = (prod(At, 2) * ones(1, length(T2)))^(ones(size(At, 1), 1) * T2)
        piA2 = sum(piA2)
        # FINAL CARBON AT POOL zix
        Ct = Co * piA1 + sumB_piA * piA2
        sCt[zix] = Ct
        cEco[zix] = Ct
        cEco_prev[zix] = Ct
        # CREATE A YEARLY TIME SERIES OF THE POOLS EXCHANGE TO USE IN THE NEXT
        # POOLS CALCULATIONS
        out = runForward(selected_models, forcing, out, modelnames, helpers)
        # FEED fCt
        # fCt[zix, :] = cEco[zix, :]
        fCt = cEco
    end
    # make the fx consistent with the pools
    cEco = sCt
    cEco_prev = sCt
    out = runForward(selected_models, forcing, out, modelnames, helpers)

    ## pack land variables
    @pack_nt cEco ⇒ land.pools
    return land
end
