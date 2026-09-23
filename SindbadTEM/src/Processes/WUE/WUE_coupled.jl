export WUE_coupled

struct WUE_coupled <: WUE end
#! format: on

function compute(params::WUE_coupled, forcing, land, helpers)

    @unpack_nt begin
        z_zero ⇐ land.constants
        (gpp, transpiration) ⇐ land.fluxes
    end

    ## calculate variables
    WUE = transpiration != z_zero ? gpp / transpiration : z_zero

    ## pack land variables
    @pack_nt WUE ⇒ land.diagnostics
    return land
end

purpose(::Type{WUE_coupled}) = "calculate WUE based on GPP and Tr."

@doc """

$(getModelDocString(WUE_coupled))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.09.2026 [jzhou]

*Created by*
 - jzhou
"""
WUE_coupled
