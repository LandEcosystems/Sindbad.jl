export cCycleBase_simple

#! format: off
@bounds @describe @units @timescale @with_kw struct cCycleBase_simple{T1,T2,T3} <: cCycleBase
    annk::T1 = Float64.([1, 0.03, 0.03, 1, 14.8, 3.9, 18.5, 4.8, 0.2424, 0.2424, 6, 7.3, 0.2, 0.0045]) | (Float64.([0.05, 0.002, 0.002, 0.05, 1.48, 0.39, 1.85, 0.48, 0.02424, 0.02424, 0.6, 0.73, 0.02, 0.0045]), Float64.([3.3, 0.5, 0.5, 3.3, 148.0, 39.0, 185.0, 48.0, 2.424, 2.424, 60.0, 73.0, 2.0, 0.045])) | "turnover rate of ecosystem carbon pools" | "year-1" | ""
    c_flow_A_array::T2 = Float64.([
                     -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 0.00 0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 0.00 0.00 1.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 0.00 0.00 1.00 0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     1.00 0.00 0.00 0.00 0.00 0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     1.00 0.00 0.00 0.00 0.00 0.00 0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 0.00 1.00 0.00 0.00 0.00 0.00 0.00 -1.0 0.00 0.00 0.00 0.00 0.0
                     0.00 1.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 -1.0 0.00 0.00 0.00 0.0
                     0.00 0.00 0.00 0.00 1.00 1.00 0.00 0.00 1.00 0.00 -1.0 0.00 0.00 0.0
                     0.00 0.00 0.00 0.00 0.00 0.00 1.00 1.00 0.00 1.00 0.00 -1.0 0.00 0.0
                     0.00 0.00 0.00 0.00 0.00 1.00 0.00 1.00 1.00 1.00 1.00 1.00 -1.0 0.0
                     0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 1.00 1.00 -1.0
                 ]) | (-Inf, Inf) | "Transfer matrix for carbon at ecosystem level" | "" | ""
    c_flow_MEQP_array::T2 = Float64.([
                     -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 0.00 0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 0.00 0.00 0.54 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 0.00 0.00 0.46 0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.54 0.00 0.00 0.00 0.00 0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.00 0.0
                     0.46 0.00 0.00 0.00 0.00 0.00 0.00 -1.0 0.00 0.00 0.00 0.00 0.00 0.0
                     0.00 0.00 1.00 0.00 0.00 0.00 0.00 0.00 -1.0 0.00 0.00 0.00 0.00 0.0
                     0.00 1.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 -1.0 0.00 0.00 0.00 0.0
                     0.00 0.00 0.00 0.00 0.40 0.15 0.00 0.00 0.24 0.00 -1.0 0.00 0.00 0.0
                     0.00 0.00 0.00 0.00 0.00 0.00 0.45 0.17 0.00 0.24 0.00 -1.0 0.00 0.0
                     0.00 0.00 0.00 0.00 0.00 0.43 0.00 0.43 0.28 0.28 0.40 0.43 -1.0 0.0
                     0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.005 0.0026 -1.0
                 ]) | (-Inf, Inf) | "Transfer matrix for carbon at ecosystem level" | "" | ""
    p_C_to_N_cVeg::T3 = Float64.([25.0, 260.0, 260.0, 25.0]) | (-Inf, Inf) | "carbon to nitrogen ratio in vegetation pools" | "gC/gN" | ""
end
#! format: on

function define(params::cCycleBase_simple, forcing, land, helpers)
    @unpack_cCycleBase_simple params

    @unpack_nt begin
        cEco ⇐ land.pools
    end

    # if there is flux order check that is consistent
    c_flow_order = Tuple(collect(1:length(findall(>(z_zero), c_flow_A_array))))
    c_taker = Tuple([ind[1] for ind ∈ findall(>(z_zero), c_flow_A_array)])
    c_giver = Tuple([ind[2] for ind ∈ findall(>(z_zero), c_flow_A_array)])


    ## Instantiate variables
    C_to_N_cVeg = one.(cEco)

    c_model = cCycleBase_simple()

    ## pack land variables
    @pack_nt begin
        (C_to_N_cVeg, c_flow_A_array) ⇒ land.diagnostics
        (c_flow_order, c_taker, c_giver) ⇒ land.constants
        c_model ⇒ land.models
    end
    return land
end

function compute(params::cCycleBase_simple, forcing, land, helpers)
    ## unpack parameters
    @unpack_cCycleBase_simple params

    ## unpack land variables
    @unpack_nt begin
        C_to_N_cVeg ⇐ land.diagnostics
        o_one ⇐ land.constants
    end

    ## calculate variables
    #carbon to nitrogen ratio [gC.gN-1]
    C_to_N_cVeg[getZix(land.pools.cVeg, helpers.pools.zix.cVeg)] .= p_C_to_N_cVeg

    # turnover rates
    c_eco_k_base .= annk

    ## pack land variables
    @pack_nt (C_to_N_cVeg, c_eco_k_base, c_flow_A_array) ⇒ land.diagnostics

    return land
end

poolConfiguration(::Type{<:cCycleBase_simple}) = CarbonPoolsCASA
purpose(::Type{cCycleBase_simple}) = "Structure and properties of the carbon cycle components as needed for a simplified version of the CASA approach."

@doc """

$(getModelDocString(cCycleBase_simple))

---

# Extended help

*References*
 - Potter; C. S.; J. T. Randerson; C. B. Field; P. A. Matson; P. M.  Vitousek; H. A. Mooney; & S. A. Klooster. 1993. Terrestrial ecosystem  production: A process model based on global satellite & surface data.  Global Biogeochemical Cycles. 7: 811-841.

*Versions*
 - 1.0.0 on 28.02.2020.0 [sbesnard]  

*Created by*
 - ncarvalhais
"""
cCycleBase_simple
