export cTauSoilW_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cTauSoilW_CASA{T1} <: cTauSoilW
    Aws::T1 = 1.0 | (0.001, 1000.0) | "curve (expansion/contraction) controlling parameter" | "" | ""
end
#! format: on

function define(params::cTauSoilW_CASA, forcing, land, helpers)
    @unpack_nt begin
        (soilW, cEco) ⇐ land.pools
        o_one ⇐ land.constants
    end

    ## Instantiate variables
    c_eco_k_f_soilW = one.(cEco)
    fsoilW = o_one
    fsoilW_prev = o_one
    # BGME was defined on monthly totals, so the stored soil water is spread over the
    # time steps of a month. A month is 30 days, as in TIMESCALE_DAY_MULTIPLIER.
    timesteps_per_month = oftype(o_one, inv(getUnitConversionForParameter("month", helpers.dates.temporal_resolution)))
    soilW_prev = totalS(soilW)

    ## pack land variables
    @pack_nt (c_eco_k_f_soilW, fsoilW, fsoilW_prev) ⇒ land.diagnostics
    @pack_nt (soilW_prev, timesteps_per_month) ⇒ land.cTauSoilW
    return land
end

function compute(params::cTauSoilW_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cTauSoilW_CASA params

    ## unpack land variables
    @unpack_nt begin
        (c_eco_k_f_soilW, fsoilW_prev) ⇐ land.diagnostics
        (soilW_prev, timesteps_per_month) ⇐ land.cTauSoilW
        soilW ⇐ land.pools
        (rain, PET) ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
    end

    # Belowground moisture effect (BGME) of Century. Without evaporative demand the
    # previous value is kept.
    if PET > z_zero
        # BELOW GROUND RATIO, adjusted by Aws
        BGRATIO = (soilW_prev / timesteps_per_month + rain) / PET * Aws
        if BGRATIO < z_zero
            BGME = o_one
        elseif BGRATIO < o_one
            BGME = oftype(o_one, 0.1) + oftype(o_one, 0.9) * BGRATIO
        elseif BGRATIO <= oftype(o_one, 2)
            BGME = o_one
        elseif BGRATIO <= oftype(o_one, 30)
            BGME = o_one + oftype(o_one, 1 / 28) - oftype(o_one, 0.5 / 28) * BGRATIO
        else
            BGME = oftype(o_one, 0.5)
        end
    else
        BGME = fsoilW_prev
    end
    fsoilW = at_least_zero(at_most_one(BGME))

    # set the same moisture stress to all carbon pools
    for zix ∈ eachindex(c_eco_k_f_soilW)
        @rep_elem fsoilW ⇒ (c_eco_k_f_soilW, zix)
    end
    soilW_prev = totalS(soilW)
    fsoilW_prev = fsoilW

    ## pack land variables
    @pack_nt (c_eco_k_f_soilW, fsoilW, fsoilW_prev) ⇒ land.diagnostics
    @pack_nt soilW_prev ⇒ land.cTauSoilW
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
 - 1.1 on 11.10.2026 [skoirala]: ported the vectorized BGME code to a per time step scalar
   form, with the previous total soil water kept in land.cTauSoilW and the time steps per
   month taken from the model time step

*Created by*
 - ncarvalhais

Notesthe BGME is used as a scalar dependent on soil moisture; as the  sum of soil moisture for all layers. This can be partitioned into  different soil layers in the soil & affect independently the  decomposition processes of pools that are at the surface & deeper in  the soils.
"""
cTauSoilW_CASA
