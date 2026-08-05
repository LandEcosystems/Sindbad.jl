export vegFraction_scaledfAPAR

#! format: off
@bounds @describe @units @timescale @with_kw struct vegFraction_scaledfAPAR{T1} <: vegFraction
    fAPAR_scalar::T1 = 10.0 | (0.0, 20.0) | "scalar for fAPAR" | "" | ""
end
#! format: on

function define(params::vegFraction_scaledfAPAR, forcing, land, helpers)
    ## unpack parameters
    @unpack_vegFraction_scaledfAPAR params

    ## unpack land variables
    @unpack_nt begin
        z_zero ⇐ land.constants
    end

    ## calculate variables
    fAPAR = z_zero

    ## pack land variables
    @pack_nt fAPAR ⇒ land.states
    return land
end

function compute(params::vegFraction_scaledfAPAR, forcing, land, helpers)
    ## unpack parameters
    @unpack_vegFraction_scaledfAPAR params

    ## unpack land variables
    @unpack_nt begin
        fAPAR ⇐ land.states
    end

    ## calculate variables
    frac_vegetation = at_most_one(fAPAR * fAPAR_scalar)

    ## pack land variables
    @pack_nt frac_vegetation ⇒ land.states
    return land
end

purpose(::Type{vegFraction_scaledfAPAR}) = "Vegetation fraction as a linear function of fAPAR."

@doc """

$(getModelDocString(vegFraction_scaledfAPAR))

---

# Extended help

*References*

*Versions*
 - 1.1 on 24.10.2020 [ttraut]: new module  

*Created by*
 - sbesnard
"""
vegFraction_scaledfAPAR
