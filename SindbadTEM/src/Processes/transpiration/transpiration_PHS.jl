export transpiration_PHS

struct transpiration_PHS <: transpiration end

function compute(params::transpiration_PHS, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        (phs_transpiration, tran_gs) ⇐ land.diagnostics
        root_water_uptake ⇐ land.fluxes
    end
    
    transpiration = min(tran_gs, totalS(root_water_uptake))

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
