export snowFraction_binary

struct snowFraction_binary <: snowFraction end

function compute(params::snowFraction_binary, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        snowW ⇐ land.pools
        ΔsnowW ⇐ land.pools
        (z_zero, o_one) ⇐ land.constants
    end

    # if there is snow; then snow fraction is 1; otherwise 0
    tot_snow = totalS(snowW, ΔsnowW)
    frac_snow = ifelse(tot_snow > z_zero, one(tot_snow), zero(tot_snow))

    ## pack land variables
    @pack_nt frac_snow ⇒ land.states
    return land
end

purpose(::Type{snowFraction_binary}) = "Snow cover fraction using a binary approach."

@doc """

$(getModelDocString(snowFraction_binary))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code  

*Created by*
 - mjung
"""
snowFraction_binary
