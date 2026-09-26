export fAPAR_linear

#! format: off
@bounds @describe @units @timescale @with_kw struct fAPAR_linear{T1} <: fAPAR
    slope::T1 = 1.24 | (0.00001, 2.0) | "slope contorlling FPAR" | "" | ""
    intercept::T1 = 0.17 | (0.00001, 0.99) | "linear fraction of fAPAR and frac_vegetation" | "" | ""

end
#! format: on

function compute(params::fAPAR_linear, forcing, land, helpers)
    @unpack_fAPAR_linear params

    ## unpack land variables
    @unpack_nt NDVI ⇐ land.states

    ## calculate variables
    fAPAR = slope * NDVI + intercept

    ## pack land variables
    @pack_nt fAPAR ⇒ land.states
    return land
end

purpose(::Type{fAPAR_linear}) = "fAPAR as a linear function of NDVI."

@doc """

$(getModelDocString(fAPAR_linear))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]  

*Created by*
 - skoirala | @dr-ko
"""
fAPAR_linear
