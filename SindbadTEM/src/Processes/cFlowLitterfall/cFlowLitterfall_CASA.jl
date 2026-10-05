export cFlowLitterfall_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cFlowLitterfall_CASA{T1} <: cFlowLitterfall
    max_min_LAI::T1 = 12.0 | (11.0, 13.0) | "maximum value for the minimum LAI for litter scalars" | "m2/m2" | ""
end
#! format: on

function define(params::cFlowLitterfall_CASA, forcing, land, helpers)
    @unpack_nt begin
        cEco ⇐ land.pools
        LAI ⇐ land.states
    end

    TSPY = floor(Int, helpers.dates.timesteps_in_year)
    LAI13 = fill(zero(LAI), TSPY + 1)

    @pack_nt (leaf_shedding_frac, root_shedding_frac) ⇒ land.diagnostics
    @pack_nt LAI13 ⇒ land.states
    return land
end

function compute(params::cFlowLitterfall_CASA, forcing, land, helpers)
    @unpack_cFlowLitterfall_CASA params
    @unpack_nt begin
        (LAI, LAI13) ⇐ land.states
    end

    TSPY = floor(Int, helpers.dates.timesteps_in_year)

    LAI_of_pastyear = LAI13[1:(TSPY - 1)]
    LAI13 = circshift(LAI13, 1)
    LAI13 = repElem(LAI13, LAI, 1)

    # Calculate δLAI and its sum over the year
    dLAI = diff(LAI13)
    dLAI = at_least_zero(dLAI)
    dLAIsum = sum(dLAI)

    # Calculate average & minimum LAI
    LAIsum = sum(LAI_of_pastyear)
    LAIave = LAIsum / size(LAI_of_pastyear, 2)
    LAImin = min(mininum(LAI_of_pastyear), max_min_LAI)

    # Calculate constant fraction of LAI [LTCON]
    LTCON = LAIave > 0.0 ? at_most_one(at_least_zero(safe_divide(LAImin, LAIave))) : zero(LAI)

    # Calculate variable fraction of LAI [LTCON]
    LTVAR = (dLAI <= zero(LAI)  | dLAIsum <= zero(LAI)) ? zero(LAI) : safe_divide(dLAI[1], dLAIsum)

    # Calculate the scalar for leaf litterfall and feed it to cCycle components
    # here, unlike in CASA, there is not an implicit constant fraction of root litter inputs
    shedding_frac = (LTCON  + (1.0 - LTCON) * LTVAR)

    ## pack land variables
    @pack_nt begin 
        (
            LAI13, 
            shedding_frac,
            ) ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFlowLitterfall_CASA}) = "Seasonally distributes CASA vegetation turnover into leaf and fine-root litterfall using LAI dynamics. NOT TESTED"

@doc """

$(getModelDocString(cFlowLitterfall_CASA))

---

# Extended help

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].
 - Potter, C., Klooster, S., Myneni, R., Genovese, V., Tan, P. N., & Kumar, V. (2003).  Continental-scale comparisons of terrestrial carbon sinks estimated from satellite data & ecosystem  modeling 1982–1998. Global & Planetary Change, 39[3-4], 201-213.
 - Potter; C. S.; J. T. Randerson; C. B. Field; P. A. Matson; P. M.  Vitousek; H. A. Mooney; & S. A. Klooster. 1993. Terrestrial ecosystem  production: A process model based on global satellite & surface data.  Global Biogeochemical Cycles. 7: 811-841.
 - Potter; C. S.; Randerson; J. T.; Field; C. B.; Matson; P. A.; Vitousek; P. M.; Mooney; H. A.  & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global  satellite & surface data. Global Biogeochemical Cycles, 7[4], 811-841.

*Versions*
 - 1.0 on 12.01.2020 [sbesnard]
 - 1.0 on 12.01.2020 [sbesnard]  
 - 1.1 on 05.11.2020 [skoirala | @dr-ko]: speedup  

*Created by*
 - ncarvalhais
"""
cFlowLitterfall_CASA
