export cMicrobialEfficiency_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiency_CASA{T1,T2,T3} <: cMicrobialEfficiency
    effA::T1 = 0.85 | (0.0, 1.0) | "Intercept of the linear of microbial carbon-transfer efficiency to soil texture." | "" | ""
    effB::T2 = 0.68 | (0.0, Inf) | "Sensitivity of microbial carbon-transfer efficiency to soil texture (silt+clay fraction)." | "" | ""
    c_flow_ME_array::T3 = Float64.([
                    -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
                    0.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
                    0.0 0.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
                    0.0 0.0 0.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
                    0.0 0.0 0.0 1.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
                    0.0 0.0 0.0 1.0 0.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
                    1.0 0.0 0.0 0.0 0.0 0.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
                    1.0 0.0 0.0 0.0 0.0 0.0 0.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0
                    0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0 -1.0 0.0 0.0 0.0 0.0 0.0
                    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 -1.0 0.0 0.0 0.0 0.0
                    0.0 0.0 0.0 0.0 0.4 0.4 0.0 0.0 0.4 0.0 -1.0 0.0 0.0 0.0
                    0.0 0.0 0.0 0.0 0.0 0.0 0.45 0.45 0.0 0.4 0.0 -1.0 0.45 0.45
                    0.0 0.0 0.0 0.0 0.0 0.6 0.0 0.55 0.6 0.6 0.4 0.0 -1.0 0.0
                    0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.45 -1.0
                ]) | (-Inf, Inf) | "Microbial efficiency transfer matrix for carbon at ecosystem level" | "" | ""

end
#! format: on

function define(params::cMicrobialEfficiency_CASA, forcing, land, helpers)
    
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # Allocate one value per active carbon transfer. Start from 
    # one so that vegetation flows, not mediated by microbial activity, are unchanged.
    c_flow_ME_vec = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_ME_vec ⇒ land.diagnostics
	return land
end

function precompute(params::cMicrobialEfficiency_CASA, forcing, land, helpers)
    @unpack_cMicrobialEfficiency_CASA params
    @unpack_nt begin
        c_flow_ME_vec ⇐ land.diagnostics
        (c_flow_order, c_giver, c_taker) ⇐ land.cCycleBase
        # (cLit, cSoil, cMic) ⇐ land.pools
        (st_clay, st_silt) ⇐ land.properties
        # CASA already has a c_flow_ME_array that will be the prior here... 
        # the values computed here in this function cannot replace the 
        # values in this prior throw a warning if so!
        # c_flow_E_array ⇐ land.diagnostics
    end

    # Collapse the soil profile to the same mean clay and silt fractions, and estimate
    # a microbial efficiency from it
    clay = mean(st_clay)
    silt = mean(st_silt)

	# CASA microbial transfer efficiency:
    #     E = effA - effB * (silt + clay)
    microbial_efficiency = clamp_zero_one(effA - effB * (silt + clay))

    # c_flow_ME_array. These were absolute positions (13,12) and (14,12), correct
    # only for one 14-pool ordering; resolving the names instead holds under any
    # structure that has them, and writes nothing at all under one that does not.
    for giver ∈ helpers.pools.zix.cMicSoil
        for taker ∈ helpers.pools.zix.cSoilSlow      # cMicSoil -> cSoilSlow
            c_flow_ME_array[taker, giver] = microbial_efficiency
        end
        for taker ∈ helpers.pools.zix.cSoilOld       # cMicSoil -> cSoilOld
            c_flow_ME_array[taker, giver] = microbial_efficiency
        end
    end

    for fO ∈ c_flow_order
        give_r = c_giver[fO]
        take_r = c_taker[fO]
        # repElem(v::SVector, v_elem, v_zero, v_one, ind::Int)
        c_flow_ME_vec = repElem(c_flow_ME_vec, c_flow_ME_array[take_r,give_r], c_flow_ME_vec, c_flow_ME_vec, fO)
    end

    @pack_nt (c_flow_ME_vec, c_flow_ME_array) ⇒ land.diagnostics
	return land
end

purpose(::Type{cMicrobialEfficiency_CASA}) = "Microbial efficiency is defined as a function of texture."

@doc """ 

	$(getModelDocString(cMicrobialEfficiency_CASA))

---

# Extended help

*References*

*Versions*
 - 1.0 on 27.08.2026 [sol]

*Created by*
 - sol

"""
cMicrobialEfficiency_CASA

