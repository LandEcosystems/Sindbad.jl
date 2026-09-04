export cMicrobialEfficiency_texture

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiency_texture{T1,T2} <: cMicrobialEfficiency
    effA::T1 = 0.85 | (0.0, 1.0) | "Intercept of the linear of microbial carbon-transfer efficiency to soil texture." | "" | ""
    effB::T2 = 0.68 | (0.0, Inf) | "Sensitivity of microbial carbon-transfer efficiency to soil texture (silt+clay fraction)." | "" | ""
end
#! format: on

function define(params::cMicrobialEfficiency_texture, forcing, land, helpers)
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

function precompute(params::cMicrobialEfficiency_texture, forcing, land, helpers)
    @unpack_cMicrobialEfficiency_texture params
    @unpack_nt begin
        c_flow_ME_vec ⇐ land.diagnostics
        (c_flow_order, c_giver, c_taker) ⇐ land.cCycleBase
        (cLit, cSoil) ⇐ land.pools
        (st_clay, st_silt) ⇐ land.properties
    end

    # Collapse the soil profile to the same mean clay and silt fractions, and estimate
    # a microbial efficiency from it
    clay = mean(st_clay)
    silt = mean(st_silt)
    microbial_efficiency = clamp_zero_one(effA - effB * (silt + clay))

    # Find litter and soil pools, where flows are mediated by microbial activity, 
    # and attribute microbial efficiency.
    zix_cLit = getZix(cLit, helpers.pools.zix.cLit)
    zix_cSoil = getZix(cSoil, helpers.pools.zix.cSoil)

    for fO ∈ c_flow_order
        give_r = c_giver[fO]
        is_decomposition = (give_r ∈ zix_cLit || give_r ∈ zix_cSoil)
        me_value = is_decomposition ? microbial_efficiency : one(microbial_efficiency)
        # @show give_r, is_decomposition, me_value
        c_flow_ME_vec = repElem(c_flow_ME_vec, me_value, c_flow_ME_vec, c_flow_ME_vec, fO)
    end

    @pack_nt c_flow_ME_vec ⇒ land.diagnostics
	return land
end

purpose(::Type{cMicrobialEfficiency_texture}) = "Microbial efficiency is defined as a function of texture, similar to CASA."

@doc """ 

	$(getModelDocString(cMicrobialEfficiency_texture))

---

# Extended help

The approach computes

`c_ME = clamp_zero_one(effA - effB * (mean(st_silt) + mean(st_clay)))`

and assigns it to active `cLit/cSoil -> cLit/cSoil` transfers identified from
`c_giver` and `c_taker`. All other transfers receive the value 1.

The approach is like the CASA implementation. This approach is named
texture because the mechanism is the texture response itself, independent
if the rest of the carbon cycle uses a CASA approach.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 27.08.2026 [sol]

*Created by*
 - sol

"""
cMicrobialEfficiency_texture
