export cTauSoilProperties_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cTauSoilProperties_CASA{T1} <: cTauSoilProperties
    TEXTEFFA::T1 = 0.75 | (0.0, 1.0) | "effect of soil texture on turnove times" | "" | ""
end
#! format: on

function define(params::cTauSoilProperties_CASA, forcing, land, helpers)
    @unpack_cTauSoilProperties_CASA params
    @unpack_nt cEco ⇐ land.pools

    ## Instantiate variables
    c_eco_k_f_soil_props = one.(cEco)

    ## pack land variables
    @pack_nt c_eco_k_f_soil_props ⇒ land.diagnostics
    return land
end

function compute(params::cTauSoilProperties_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cTauSoilProperties_CASA params

    ## unpack land variables
    @unpack_nt c_eco_k_f_soil_props ⇐ land.diagnostics

    ## unpack land variables
    @unpack_nt (st_clay, st_silt) ⇐ land.properties

    ## calculate variables
    #sujan: moving clay & silt from land.properties to p_soilWBase.
    clay = mean(st_clay)
    silt = mean(st_silt)
    # TEXTURE EFFECT ON k OF cMicSoil
    zix = hasproperty(helpers.pools.zix, :cMicSoil) ? helpers.pools.zix.cMicSoil : nothing
    if zix !== nothing
        c_eco_k_f_soil_props[zix] = (1.0 - (TEXTEFFA * (silt + clay)))
    end
    # (ineficient, should be pix zix_mic)

    ## pack land variables
    @pack_nt c_eco_k_f_soil_props ⇒ land.diagnostics
    return land
end

purpose(::Type{cTauSoilProperties_CASA}) = "Compute soil texture effects on turnover rates [k] of cMicSoil"

@doc """

$(getModelDocString(cTauSoilProperties_CASA))

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
cTauSoilProperties_CASA
