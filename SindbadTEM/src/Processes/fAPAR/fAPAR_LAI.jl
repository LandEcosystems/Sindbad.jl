export fAPAR_LAI

#! format: off
@bounds @describe @units @timescale @with_kw struct fAPAR_LAI{T1} <: fAPAR
    k_extinction::T1 = 0.5 | (0.3, 0.8) | "effective light extinction coefficient" | "" | ""
end
#! format: on

function compute(params::fAPAR_LAI, forcing, land, helpers)
    @unpack_fAPAR_LAI params

    ## unpack land variables
    @unpack_nt begin
        LAI ⇐ land.states
        (z_zero, o_one) ⇐ land.constants
    end
    ## calculate variables
    fAPAR = o_one - exp(-(LAI * k_extinction))

    ## pack land variables
    @pack_nt begin
        fAPAR ⇒ land.states
        k_extinction ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{fAPAR_LAI}) = "fAPAR as a function of LAI."

@doc """

$(getModelDocString(fAPAR_LAI))

---

# Extended help

*References*

*Versions*
 - 1.0 on 24.02.2021 [skoirala | @dr-ko]  

*Created by*
 - skoirala | @dr-ko
"""
fAPAR_LAI
