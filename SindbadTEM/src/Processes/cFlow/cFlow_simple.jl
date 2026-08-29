export cFlow_simple

struct cFlow_simple <: cFlow end

function compute(params::cFlow_simple, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt c_flow_A_array ⇐ land.diagnostics

# needs revamp
    ## calculate variables
    #@nc : this needs to go in the full..
    # Do A matrix..
    c_flow_A_vec = repeat(reshape(c_flow_A_array, [1 size(c_flow_A_array)]), 1, 1)
    # transfers
    (c_taker, c_giver) = find(squeeze(sum(c_flow_A_vec > 0.0)) >= 1)
    p_taker = c_taker
    p_giver = c_giver
    # if there is flux order check that is consistent
    if !isfield(land.constants, :c_flow_order)
        c_flow_order = 1:length(c_taker)
    else
        if length(c_flow_order) != length(c_taker)
            error("ERR : cFlowAct_simple : " * "length(c_flow_order) != length(c_taker)")
        end
    end
# needs revamp

    ## pack land variables
    @pack_nt begin
        c_flow_order ⇒ land.constants
        (c_flow_A_vec, p_giver, p_taker) ⇒ land.cFlow
    end
    return land
end

purpose(::Type{cFlow_simple}) = "Carbon transfer rates between pools modeled a simplified version of CASA."

@doc """

$(getModelDocString(cFlow_simple))

---

# Extended help

*References*

*Versions*
 - 1.0 on 13.01.2020 [sbesnard]  

*Created by*
 - ncarvalhais
"""
cFlow_simple
