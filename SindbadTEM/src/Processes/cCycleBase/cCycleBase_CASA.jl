export cCycleBase_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cCycleBase_CASA{T1,T2,T3,T4,T5,T6} <: cCycleBase
    annk::T1 = Float64.([1, 0.03, 0.03, 1, 14.8, 3.9, 18.5, 4.8, 0.2424, 0.2424, 6, 7.3, 0.2, 0.0045]) | (Float64.([0.05, 0.002, 0.002, 0.05, 1.48, 0.39, 1.85, 0.48, 0.02424, 0.02424, 0.6, 0.73, 0.02, 0.0045]), Float64.([3.3, 0.5, 0.5, 3.3, 148.0, 39.0, 185.0, 48.0, 2.424, 2.424, 60.0, 73.0, 2.0, 0.045])) | "turnover rate of ecosystem carbon pools" | "year-1" | ""
    cVegRootFine_age_per_PFT::T2 = Float64.([1.8, 1.2, 1.2, 5.0, 1.8, 1.0, 1.0, 0.0, 1.0, 2.8, 1.0, 1.0]) | (Float64.([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]), Float64.([20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0])) | "mean age of fine roots" | "yr" | ""
    cVegRootCoarse_age_per_PFT::T3 = Float64.([41.0, 58.0, 58.0, 42.0, 27.0, 25.0, 25.0, 0.0, 5.5, 40.0, 1.0, 40.0]) | (Float64.([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]), Float64.([100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0])) | "mean age of coarse roots" | "yr" | ""
    cVegWood_age_per_PFT::T4 = Float64.([41.0, 58.0, 58.0, 42.0, 27.0, 25.0, 25.0, 0.0, 5.5, 40.0, 1.0, 40.0]) | (Float64.([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]), Float64.([100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0])) | "mean age of wood" | "yr" | ""
    cVegLeaf_age_per_PFT::T5 = Float64.([1.8, 1.2, 1.2, 5.0, 1.8, 1.0, 1.0, 0.0, 1.0, 2.8, 1.0, 1.0]) | (Float64.([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]), Float64.([20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0])) | "mean age of leafs" | "yr" | ""
    p_C_to_N_cVeg::T6 = Float64.([25.0, 260.0, 260.0, 25.0]) | (-Inf, Inf) | "carbon to nitrogen ratio in vegetation pools" | "gC/gN" | ""
end
#! format: on

function define(params::cCycleBase_CASA, forcing, land, helpers)
    @unpack_cCycleBase_CASA params

    @unpack_nt begin
        cEco ⇐ land.pools
    end

    # one flow per declared edge of this approach, resolved against the configured
    # pool structure, rather than a transfer matrix carried as a parameter. The same
    # call keys the flows by pool-name pair and sizes the neutral flow vector, so a
    # cFlow approach reads the topology and fills in values instead of rederiving both
    (c_flow_order, c_taker, c_giver, c_flow_named_edges, c_flow_A_vec, c_flow_QP_vec,
        c_flow_ME_vec) = cFlowStructure(params, cEco, helpers)

    ## Instantiate variables
    C_to_N_cVeg = one.(cEco)

    c_model = cCycleBase_CASA()

    ## pack land variables
    @pack_nt begin
        (C_to_N_cVeg, c_flow_A_vec, c_flow_QP_vec, c_flow_ME_vec) ⇒ land.diagnostics
        (c_flow_order, c_taker, c_giver, c_flow_named_edges) ⇒ land.cCycleBase
        c_model ⇒ land.models
    end
    return land
end

# all the parameters that are required for tau and for QP ME should be loaded here...


function compute(params::cCycleBase_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cCycleBase_CASA params

    ## unpack land variables
    @unpack_nt begin
        C_to_N_cVeg ⇐ land.diagnostics
        o_one ⇐ land.constants
    end

    ## calculate variables
    # carbon to nitrogen ratio [gC.gN-1]
    C_to_N_cVeg[helpers.pools.zix.cVeg] .= p_C_to_N_cVeg

    # turnover rates
    c_eco_k_base .= annk

    ## pack land variables
    @pack_nt (c_eco_k_base) ⇒ land.diagnostics
    return land
end

poolConfiguration(::Type{<:cCycleBase_CASA}) = CarbonPoolsCASA
cFlowEdges(::Type{<:cCycleBase_CASA}) = CASA_FLOW_EDGES
purpose(::Type{cCycleBase_CASA}) = "Structure and properties of the carbon cycle components used in the CASA approach."

@doc """

$(getModelDocString(cCycleBase_CASA))

---

# Extended help

# Pool topology

The 22 giver-to-taker links of this approach are declared as `CASA_FLOW_EDGES` in
`poolConfigurations/CASA.jl`, and the pools they name as
`poolStructure(CarbonPoolsCASA)` beside it. `cFlowMatrix(cCycleBase_CASA, pool_names)`
returns them as a `[taker, giver]` matrix of flow indices, and `plotCarbonFlows`
draws them, so neither has to be transcribed here to be read.

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].
 - Potter, C., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003).  Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data & ecosystem  modeling 1982–1998. Global & Planetary Change, 39[3-4], 201-213.
 - Potter; C. S.; Randerson; J. T.; Field; C. B.; Matson; P. A.; Vitousek; P. M.; Mooney; H. A.  & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global  satellite & surface data. Global Biogeochemical Cycles, 7[4], 811-841.

*Versions*
 - 1.0 on 28.05.2022 [skoirala | @dr-ko]: migrate to julia  
 - 1.1 on 04.09.2026 [skoirala]: c_flow_ME_vec allocated here; dead c_flow_MEQP_array parameter and the transcribed c_flow_A_array removed

*Created by*
 - ncarvalhais
"""
cCycleBase_CASA
