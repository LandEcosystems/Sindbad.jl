export PFT_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct PFT_constant{T1} <: PFT
    PFT::T1 = 1.0 | (1.0, 13.0) | "Plant functional type" | "class" | ""
end
#! format: on

function precompute(params::PFT_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_PFT_constant params

    ## pack land variables
    @pack_nt PFT ⇒ land.states
    return land
end

purpose(::Type{PFT_constant}) = "Sets a uniform PFT class."

@doc """

$(getModelDocString(PFT_constant))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code  

*Created by*
 - unknown [xxx]
"""
PFT_constant
