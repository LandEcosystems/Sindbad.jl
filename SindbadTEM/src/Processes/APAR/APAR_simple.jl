export APAR_simple

#! format: off
@bounds @describe @units @timescale @with_kw struct APAR_simple{T1} <: APAR
    epar::T1    = 2.1739e5 | (1e5, 3e5) | "Energy content of PAR" | "J mol⁻¹" | ""
    lai_min::T1 = 1e-10    | (1e-12, 1e-4) | "Minimum LAI for numerical stability" | "m2 m⁻2" | ""
end
#! format: on

function compute(params::APAR_simple, forcing, land, helpers)

    @unpack_APAR_simple params

    @unpack_nt begin
        f_rg ⇐ forcing
        MJ_to_J ⇐ land.constants
        d_to_s ⇐ land.constants
        fAPAR ⇐ land.states
        LAI   ⇐ land.states
    end

    # unpack output variable
    f_rg_W = f_rg * MJ_to_J / d_to_s   # MJ/m²/d → W/m²


    # Convert PAR from W m⁻2 to mol photons m⁻2 s⁻1
    par_down_mol = f_rg_W  / epar

    # Absorbed PAR per leaf area
    APAR = par_down_mol *fAPAR / max(LAI, lai_min)

    @pack_nt APAR ⇒ land.states
    
    return land
end



purpose(::Type{APAR_simple}) =
    "Simple APAR calculation from PAR, fAPAR and LAI."

@doc """

$(getModelDocString(APAR_simple))

---

# Extended help

Computes absorbed PAR per unit leaf area using:

    APAR = (PAR / Epar) * fAPAR / LAI

This method assumes fAPAR and LAI are provided
by independent processes.

No radiative transfer is calculated.

"""
APAR_simple