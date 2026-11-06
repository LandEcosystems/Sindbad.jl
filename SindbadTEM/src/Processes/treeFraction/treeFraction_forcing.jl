export treeFraction_forcing

struct treeFraction_forcing <: treeFraction end

function compute(params::treeFraction_forcing, forcing, land, helpers)
    ## unpack forcing
    @unpack_nt f_tree_frac ⇐ forcing

    frac_tree = f_tree_frac
    ## pack land variables
    @pack_nt frac_tree ⇒ land.states
    return land
end

purpose(::Type{treeFraction_forcing}) = "Gets tree cover fraction from forcing data."

@doc """

$(getModelDocString(treeFraction_forcing))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]
 - 1.1 on 15.10.2026 [skoirala]: use the forcing directly as it is a scalar at the
   time step

*Created by*
 - skoirala | @dr-ko
"""
treeFraction_forcing
