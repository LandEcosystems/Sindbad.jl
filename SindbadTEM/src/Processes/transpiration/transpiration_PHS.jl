export transpiration_PHS

struct transpiration_PHS <: transpiration end

function compute(params::transpiration_PHS, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        phs_transpiration ⇐ land.diagnostics
    end
    # At convergence the layer uptake sum equals the hydraulically attenuated
    # transpiration returned by plantHydraulics_PHS.
    transpiration = phs_transpiration

    ## pack land variables
    @pack_nt transpiration ⇒ land.fluxes
    return land
end

purpose(::Type{transpiration_PHS}) = "Transpiration is calculated from PHS."

@doc """

$(getModelDocString(transpiration_PHS))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.09.2026 [jzhou]

*Created by*
 - jzhou

*Notes*
"""
transpiration_PHS
