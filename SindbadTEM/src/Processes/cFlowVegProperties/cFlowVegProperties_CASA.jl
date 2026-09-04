export cFlowVegProperties_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cFlowVegProperties_CASA{T1} <: cFlowVegProperties
    frac_lignin_wood::T1 = 0.4 | (-Inf, Inf) | "fraction of wood that is lignin" | "" | ""
end
#! format: on

function define(params::cFlowVegProperties_CASA, forcing, land, helpers)
    @unpack_cFlowVegProperties_CASA params
    @unpack_nt begin 
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end
    ## Instantiate variables
    p_F_vec = getVectorOfType(cEco, length(c_taker))

    ## pack land variables
    @pack_nt p_F_vec ⇒ land.cFlowVegProperties
    return land
end

function compute(params::cFlowVegProperties_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cFlowVegProperties_CASA params

    ## unpack land variables
    @unpack_nt begin 
        p_F_vec ⇐ land.cFlowVegProperties
        cEco ⇐ land.pools
    end
    ## calculate variables
    # p_fVeg = zeros(nPix, length(info.model.c.nZix)); #sujan
    #p_fVeg = zero(cEco)
    p_E_vec = p_F_vec
    # ADJUST cFlow BASED ON PARTICULAR PARAMETERS # SOURCE, TARGET, INCREMENT aM = (:cVegLeaf, :cLitLeafFast, MTF;, :cVegLeaf, :cLitLeafSlow, 1, -, MTF;, :cVegWood, :cLitWood, 1;, :cVegRootFine, :cLitRootFineFast, MTF;, :cVegRootFine, :cLitRootFineSlow, 1, -, MTF;, :cVegRootCoarse, :cLitRootCoarse, 1;, :cLitLeafSlow, :cSoilSlow, SCLIGNIN;, :cLitLeafSlow, :cMicSurf, 1, -, SCLIGNIN;, :cLitRootFineSlow, :cSoilSlow, SCLIGNIN;, :cLitRootFineSlow, :cMicSoil, 1, -, SCLIGNIN;, :cLitWood, :cSoilSlow, frac_lignin_wood;, :cLitWood, :cMicSurf, 1, -, frac_lignin_wood;, :cLitRootCoarse, :cSoilSlow, frac_lignin_wood;, :cLitRootCoarse, :cMicSoil, 1, -, frac_lignin_wood;, :cSoilOld, :cMicSoil, 1;, :cLitLeafFast, :cMicSurf, 1;, :cLitRootFineFast, :cMicSoil, 1;, :cMicSurf, :cSoilSlow, 1;)
    for ii ∈ 1:size(aM, 1)
        ndxSrc = getproperty(helpers.pools.zix, aM[ii, 1])
        ndxTrg = getproperty(helpers.pools.zix, aM[ii, 2]) #sujan is this 2 | 1?
        for iSrc ∈ eachindex(ndxSrc)
            for iTrg ∈ eachindex(ndxTrg)
                # p_fVeg[ndxTrg[iTrg], ndxSrc[iSrc]] = aM(ii, 3)
                p_F_vec[ndxTrg[iTrg], ndxSrc[iSrc]] = aM[ii, 3] #sujan
            end
        end
    end

    ## pack land variables
    @pack_nt (p_E_vec, p_F_vec) ⇒ land.cFlowVegProperties
    return land
end

purpose(::Type{cFlowVegProperties_CASA}) = "Effect of vegetation properties on carbon transfers between pools as modeled in CASA."

@doc """

$(getModelDocString(cFlowVegProperties_CASA))

---

# Extended help

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].
 - Potter, C., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003).  Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data & ecosystem  modeling 1982–1998. Global & Planetary Change, 39[3-4], 201-213.
 - Potter; C. S.; Randerson; J. T.; Field; C. B.; Matson; P. A.; Vitousek; P. M.; Mooney; H. A.  & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global  satellite & surface data. Global Biogeochemical Cycles, 7[4], 811-841.

*Versions*
 - 1.0 on 13.01.2020 [sbesnard]  

*Created by*
 - ncarvalhais
"""
cFlowVegProperties_CASA
