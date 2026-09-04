export PFT_forcing

struct PFT_forcing <: PFT end

function precompute(params::PFT_forcing, forcing, land, helpers)
    ## unpack forcing
    @unpack_nt f_pft ⇐ forcing

    PFT = f_pft[1]

    ## pack land variables
    @pack_nt PFT ⇒ land.states
    return land
end

purpose(::Type{PFT_forcing}) = "Gets the PFT class from forcing data."

@doc """

$(getModelDocString(PFT_forcing))

---

# Extended help

The PFT class is taken from the `f_pft` forcing variable and published as
`land.states.PFT`, which is the single source of PFT for every downstream
process. PFT is time invariant, so it is read once in `precompute`.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala
"""
PFT_forcing
