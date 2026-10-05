export cVegetationDieOff_forcing

struct cVegetationDieOff_forcing <: cVegetationDieOff end

function define(params::cVegetationDieOff_forcing, forcing, land, helpers)
    ## unpack forcing
    @unpack_nt f_dist_intensity ⇐ forcing
    c_f_cVeg_dieOff = f_dist_intensity
    @pack_nt c_f_cVeg_dieOff ⇒ land.diagnostics
    return land
end

function compute(params::cVegetationDieOff_forcing, forcing, land, helpers)
    ## unpack forcing
    @unpack_nt f_dist_intensity ⇐ forcing
    c_f_cVeg_dieOff = f_dist_intensity
    @pack_nt c_f_cVeg_dieOff ⇒ land.diagnostics
    return land
end

purpose(::Type{cVegetationDieOff_forcing}) = "Get the fraction of vegetation that die off from forcing data."

@doc """

$(getModelDocString(cVegetationDieOff_forcing))

---

# Extended help

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].

*Versions*
 - 1.0 on summer 2024

*Created by:*
 - Nuno
"""
cVegetationDieOff_forcing
