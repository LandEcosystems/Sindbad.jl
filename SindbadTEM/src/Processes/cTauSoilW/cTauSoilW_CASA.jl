export cTauSoilW_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cTauSoilW_CASA{T1} <: cTauSoilW
    Aws::T1 = 1.0 | (0.001, 1000.0) | "curve (expansion/contraction) controlling parameter" | "" | ""
end
#! format: on

function define(params::cTauSoilW_CASA, forcing, land, helpers)
    @unpack_cTauSoilW_CASA params
    @unpack_nt (soilW, cEco) ⇐ land.pools
    @unpack_nt o_one ⇐ land.constants

    ## Instantiate variables
    c_eco_k_f_soilW = one.(cEco)
    soilW_prev = zero(soilW)
    fsoilW_prev = o_one
    ## pack land variables
    @pack_nt (c_eco_k_f_soilW, fsoilW_prev) ⇒ land.diagnostics
    @pack_nt soilW_prev ⇒ land.pools

    return land
end

function compute(params::cTauSoilW_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cTauSoilW_CASA params

    ## unpack land variables
    @unpack_nt c_eco_k_f_soilW ⇐ land.diagnostics

    ## unpack land variables
    @unpack_nt begin
        rain ⇐ land.fluxes
        soilW_prev ⇐ land.pools
        fsoilW_prev ⇐ land.diagnostics
        PET ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
    end
    # NUMBER OF TIME STEPS PER YEAR -> TIME STEPS PER MONTH
    TSPY = helpers.dates.timesteps_in_year #sujan
    TSPM = TSPY / 12
    # BELOW GROUND RATIO [BGRATIO] AND BELOW GROUND MOISTURE EFFECT [BGME]
    BGRATIO = z_zero
    BGME = o_one
    # PREVIOUS TIME STEP VALUES
    pBGME = fsoilW_prev #sujan
    # FOR PET > 0
    ndx = (PET > 0)
    # COMPUTE BGRATIO
    BGRATIO[ndx] = (soilW_prev[ndx, 1] / TSPM + rain[ndx, tix]) / PET[ndx, tix]
    # ADJUST ACCORDING TO Aws
    BGRATIO = BGRATIO * Aws
    # COMPUTE BGME
    ndx1 = ndx & (BGRATIO >= 0.0 & BGRATIO < 1)
    BGME[ndx1] = 0.1 + (0.9 * BGRATIO[ndx1])
    ndx2 = ndx & (BGRATIO >= 1 & BGRATIO <= 2)
    BGME[ndx2] = 1.0
    ndx3 = ndx & (BGRATIO > 2 & BGRATIO <= 30)
    BGME[ndx3] = 1 + 1 / 28 - 0.5 / 28 * BGRATIO[ndx[ndx3]]
    ndx4 = ndx & (BGRATIO > 30)
    BGME[ndx4] = 0.5
    # WHEN PET IS 0; SET THE BGME TO THE PREVIOUS TIME STEPS VALUE
    ndxn = (PET <= 0.0)
    BGME[ndxn] = pBGME[ndxn]
    BGME = at_least_zero(at_most_one(BGME))
    # FEED IT TO THE STRUCTURE
    fsoilW = BGME
    # set the same moisture stress to all carbon pools
    c_eco_k_f_soilW[helpers.pools.zix.cEco] = fsoilW
    soilW_prev = soilW
    fsoilW_prev = fsoilW

    ## pack land variables
    @pack_nt (fsoilW, fsoilW_prev) ⇒ land.diagnostics
    @pack_nt soilW_prev ⇒ land.pools
    return land
end

purpose(::Type{cTauSoilW_CASA}) = "Effect of soil moisture on decomposition rates as modeled in CASA, using the belowground moisture effect (BGME) from the Century model."

@doc """

$(getModelDocString(cTauSoilW_CASA))

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

Notesthe BGME is used as a scalar dependent on soil moisture; as the  sum of soil moisture for all layers. This can be partitioned into  different soil layers in the soil & affect independently the  decomposition processes of pools that are at the surface & deeper in  the soils.
"""
cTauSoilW_CASA
