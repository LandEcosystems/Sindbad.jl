export cTauLAI_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cTauLAI_CASA{T1,T2} <: cTauLAI
    max_min_LAI::T1 = 12.0 | (11.0, 13.0) | "maximum value for the minimum LAI for litter scalars" | "m2/m2" | ""
    k_root_LAI::T2 = 0.3 | (0.0, 1.0) | "constant fraction of root litter inputs" | "" | ""
end
#! format: on

function define(params::cTauLAI_CASA, forcing, land, helpers)
    @unpack_cTauLAI_CASA params
    @unpack_nt cEco ⇐ land.pools

    ## Instantiate variables
    c_eco_k_f_LAI = one.(cEco)

    ## pack land variables
    @pack_nt c_eco_k_f_LAI ⇒ land.diagnostics
    return land
end

function compute(params::cTauLAI_CASA, forcing, land, helpers)
    ## unpack parameters
    @unpack_cTauLAI_CASA params

    ## unpack land variables
    @unpack_nt c_eco_k_f_LAI ⇐ land.diagnostics

    ## unpack land variables
    @unpack_nt begin
        LAI ⇐ land.states
        (c_eco_τ, c_eco_k) ⇐ land.diagnostics
    end
    # set LAI stressor on τ to ones
    TSPY = 365 #sujan
    p_cVegLeafZix = helpers.pools.zix.cVegLeaf
    # fine roots where the structure separates them, all roots otherwise. Every name
    # resolves now, so absence shows up as an empty entry rather than a missing
    # field.
    p_cVegRootZix = isempty(helpers.pools.zix.cVegRootF) ? helpers.pools.zix.cVegRoot : helpers.pools.zix.cVegRootF
    # make sure TSPY is integer
    TSPY = floor(Int, TSPY)
    if !hasproperty(land.cTaufLAI, :p_LAI13)
        p_LAI13 = repeat([0.0], 1, TSPY + 1)
    end
    # PARAMETERS
    # Get the number of time steps per year
    TSPY = helpers.dates.timesteps_in_year
    # make sure TSPY is integer
    TSPY = floor(Int, TSPY)
    # BUILD AN ANNUAL LAI MATRIX
    # get the LAI of previous time step in LAI13
    LAI13 = p_LAI13
    LAI13 = circshift(LAI13, 1)
    # LAI13[2:TSPY + 1] = LAI13[1:TSPY]; # very slow [sujan]
    LAI13[1] = LAI
    LAI13_next = LAI13[2:(TSPY+1)]
    # LAI13_prev = LAI13[1:TSPY]
    # update s
    p_LAI13 = LAI13
    # Calculate sum of δLAI over the year
    dLAI = diff(LAI13)
    dLAI = at_least_zero(dLAI)
    dLAIsum = sum(dLAI)
    # Calculate average & minimum LAI
    LAIsum = sum(LAI13_next)
    LAIave = LAIsum / size(LAI13_next, 2)
    LAImin = minimum(LAI13_next)
    LAImin[LAImin>max_min_LAI] = max_min_LAI[LAImin>max_min_LAI]
    # Calculate constant fraction of LAI [LTCON]
    LTCON = 0.0
    ndx = (LAIave > 0.0)
    LTCON[ndx] = LAImin[ndx] / LAIave[ndx]
    # Calculate δLAI
    dLAI = dLAI[1]
    # Calculate variable fraction of LAI [LTCON]
    LTVAR = 0.0
    LTVAR[dLAI<=0.0|dLAIsum<=0.0] = 0.0
    ndx = (dLAI > 0.0 | dLAIsum > 0.0)
    LTVAR[ndx] = (dLAI[ndx] / dLAIsum[ndx])
    # Calculate the scalar for litterfall
    LTLAI = LTCON / TSPY + (1.0 - LTCON) * LTVAR
    # Calculate the scalar for root litterfall
    # RTLAI = zeros(size(LTLAI))
    RTLAI = 0.0
    ndx = (LAIsum > 0.0)
    LAI131st = LAI13[1]
    RTLAI[ndx] = (1.0 - k_root_LAI) * (LTLAI[ndx] + LAI131st[ndx] / LAIsum[ndx]) / 2.0 + k_root_LAI / TSPY
    # Feed the output fluxes to cCycle components
    zix_veg = p_cVegLeafZix
    c_eco_k_f_LAI[zix_veg] = c_eco_τ[zix_veg] * LTLAI / c_eco_k[zix_veg] # leaf litter scalar
    zix_root = p_cVegRootZix
    c_eco_k_f_LAI[zix_root] = c_eco_τ[zix_root] * RTLAI / c_eco_k[zix_root] # root litter scalar

    ## pack land variables
    @pack_nt (p_LAI13, p_cVegLeafZix, p_cVegRootZix, c_eco_k_f_LAI) ⇒ land.diagnostics
    return land
end

purpose(::Type{cTauLAI_CASA}) = "Effect of LAI on turnover rates and computes the seasonal cycle of litterfall and root litterfall based on LAI variations, as modeled in CASA."

@doc """

$(getModelDocString(cTauLAI_CASA))

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
cTauLAI_CASA
