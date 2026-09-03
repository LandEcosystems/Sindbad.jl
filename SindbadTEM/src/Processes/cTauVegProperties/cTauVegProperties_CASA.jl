export cTauVegProperties_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cTauVegProperties_CASA{T1,T2,T3,T4,T5,T6,T7} <: cTauVegProperties
    LIGNIN_per_PFT::T1 = Float64.([0.2, 0.2, 0.22, 0.25, 0.2, 0.15, 0.1, 0.0, 0.2, 0.15, 0.15, 0.1]) | (-Inf, Inf) | "fraction of litter that is lignin" | "" | ""
    NONSOL2SOLLIGNIN::T2 = 2.22 | (-Inf, Inf) | "" | "" | ""
    MTFA::T3 = 0.85 | (-Inf, Inf) | "" | "" | ""
    MTFB::T4 = 0.018 | (-Inf, Inf) | "" | "" | ""
    C2LIGNIN::T5 = 0.65 | (-Inf, Inf) | "" | "" | ""
    LIGEFFA::T6 = 3.0 | (-Inf, Inf) | "" | "" | ""
    LITC2N_per_PFT::T7 = Float64.([40.0, 50.0, 65.0, 80.0, 50.0, 50.0, 50.0, 0.0, 65.0, 50.0, 50.0, 40.0]) | (-Inf, Inf) | "carbon-to-nitrogen ratio in litter" | "" | ""
end
#! format: on

function define(params::cTauVegProperties_CASA, forcing, land, helpers)
    @unpack_cTauVegProperties_CASA params
    @unpack_nt cEco ⇐ land.pools

    ## Instantiate variables
    c_eco_k_f_veg_props = one.(cEco)

    ## pack land variables
    @pack_nt c_eco_k_f_veg_props ⇒ land.diagnostics
    return land
end

function compute(params::cTauVegProperties_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cTauVegProperties_CASA params

    ## unpack land variables
    @unpack_nt begin
        PFT ⇐ land.properties
        c_eco_k_f_veg_props ⇐ land.diagnostics
        (z_zero, o_one) ⇐ land.constants
    end

    ## calculate variables
    # c_eco_τ = annk; #sujan
    # initialize the outputs to ones
    C2LIGNIN = C2LIGNIN #sujan
    ## adjust the annk that are pft dependent directly on the p matrix
    pftVec = unique(PFT)
    for cpN ∈ (:cVegRootF, :cVegRootC, :cVegWood, :cVegLeaf)
        # get average age from parameters
        AGE = z_zero #sujan
        for ij ∈ eachindex(pftVec)
            AGE[p.vegProperties.PFT==pftVec[ij]] = p.cCycleBase.([cpN "_age_per_PFT"])(pftVec[ij])
        end
        # compute annk based on age
        annk[AGE>z_zero] = o_one / AGE[AGE>z_zero]
        # feed it to the new annual turnover rates
        zix = getproperty(helpers.pools.zix, cpN)
        c_eco_τ[zix] = annk #sujan
        # c_eco_τ[zix] = annk[zix]
    end
    # feed the parameters that are pft dependent.
    pftVec = unique(PFT)
    LITC2N = z_zero
    LIGNIN = z_zero
    for ij ∈ eachindex(pftVec)
        LITC2N[p.vegProperties.PFT==pftVec[ij]] = LITC2N_per_PFT[pftVec[ij]]
        LIGNIN[p.vegProperties.PFT==pftVec[ij]] = LIGNIN_per_PFT[pftVec[ij]]
    end
    # CALCULATE FRACTION OF LITTER THAT WILL BE METABOLIC FROM LIGNIN:N RATIO
    # CALCULATE LIGNIN 2 NITROGEN SCALAR
    L2N = (LITC2N * LIGNIN) * NONSOL2SOLLIGNIN
    # DETERMINE FRACTION OF LITTER THAT WILL BE METABOLIC FROM LIGNIN:N RATIO
    MTF = MTFA - (MTFB * L2N)
    MTF[MTF<z_zero] = z_zero
    MTF = MTF
    # DETERMINE FRACTION OF C IN STRUCTURAL LITTER POOLS FROM LIGNIN
    SCLIGNIN = (LIGNIN * C2LIGNIN * NONSOL2SOLLIGNIN) / (o_one - MTF)
    # DETERMINE EFFECT OF LIGNIN CONTENT ON k OF cLitLeafS AND cLitRootFS
    LIGEFF = exp(-LIGEFFA * SCLIGNIN)
    # feed the output
    c_eco_k_f_veg_props[helpers.pools.zix.cLitLeafS] = LIGEFF
    c_eco_k_f_veg_props[helpers.pools.zix.cLitRootFS] = LIGEFF

    ## pack land variables
    @pack_nt begin
        c_eco_τ ⇒ land.diagnostics
        (C2LIGNIN, LIGEFF, LIGNIN, LITC2N, MTF, SCLIGNIN) ⇒ land.properties
        c_eco_k_f_veg_props ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cTauVegProperties_CASA}) = "Effect of vegetation type on decomposition rates as modeled in CASA."

@doc """

$(getModelDocString(cTauVegProperties_CASA))

---

# Extended help

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].
 - Potter, C., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003).  Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data & ecosystem  modeling 1982–1998. Global & Planetary Change, 39[3-4], 201-213.
 - Potter; C. S.; Randerson; J. T.; Field; C. B.; Matson; P. A.; Vitousek; P. M.; Mooney; H. A.  & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global  satellite & surface data. Global Biogeochemical Cycles, 7[4], 811-841.

*Versions*
 - 1.0 on 12.01.2020 [sbesnard]  

*Created by*
 - ncarvalhais
"""
cTauVegProperties_CASA
