export cFlow_CASA

struct cFlow_CASA <: cFlow end

function compute(params::cFlow_CASA, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        (p_E_vec, p_F_vec) ⇐ land.cFlowVegProperties
        (p_E_vec, p_F_vec) ⇐ land.diagnostics
        c_flow_E_array ⇐ land.diagnostics
        (z_zero, o_one) ⇐ land.constants
    end
    #@nc : this needs to go in the full.
    # effects of soil & veg on the [microbial] efficiency of c flows between carbon pools
    tmp = repeat(reshape(c_flow_E_array, [1 size(c_flow_E_array)]), 1, 1)
    p_E_vec = tmp + p_E_vec + p_E_vec
    # effects of soil & veg on the partitioning of c flows between carbon pools
    p_F_vec = p_F_vec + p_F_vec
    # if there is fraction [F] & efficiency is 0, make efficiency 1
    ndx = p_F_vec > z_zero & p_E_vec == zero
    p_E_vec[ndx] = o_one
    # if there is not fraction, but efficiency exists, make fraction == 1 [should give an error if there are more than 1 flux out of this pool]
    ndx = p_E_vec > z_zero & p_F_vec == zero
    p_F_vec[ndx] = o_one
    # build A
    c_flow_A_vec = p_F_vec * p_E_vec
    # transfers
    (c_taker, c_giver) = find(squeeze(sum(c_flow_A_vec > z_zero)) >= o_one)
    p_taker = c_taker
    p_giver = c_giver
    # if there is flux order check that is consistent
    if !isfield(land.constants, :c_flow_order)
        c_flow_order = 1:length(c_taker)
    else
        if length(c_flow_order) != length(c_taker)
            error(["ERR : cFlowAct_CASA : " "length(c_flow_order) != length(c_taker)"])
    end
    end

    ## pack land variables
    @pack_nt begin
        c_flow_order ⇒ land.constants
        (c_flow_A_vec, p_E_vec, p_F_vec, p_giver, p_taker) ⇒ land.cFlow
    end
    return land
end

purpose(::Type{cFlow_CASA}) = "Carbon transfer rates between pools as modeled in CASA."

@doc """

$(getModelDocString(cFlow_CASA))

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
cFlow_CASA
