export cTau_mult

struct cTau_mult <: cTau end

function define(params::cTau_mult, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        cEco ⇐ land.pools
    end
    c_eco_k = zero(cEco)

    ## pack land variables
    @pack_nt c_eco_k ⇒ land.diagnostics
    return land
end

function compute(params::cTau_mult, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_eco_k_f_veg_props ⇐ land.diagnostics
        c_eco_k_f_soilW ⇐ land.diagnostics
        c_eco_k_f_soilT ⇐ land.diagnostics
        c_eco_k_f_soil_props ⇐ land.diagnostics
        c_eco_k_f_LAI ⇐ land.diagnostics
        c_eco_k_base ⇐ land.diagnostics
        c_eco_k ⇐ land.diagnostics
    end
    for i ∈ eachindex(c_eco_k)
        tmp = c_eco_k_base[i] * c_eco_k_f_LAI[i] * c_eco_k_f_soil_props[i] * c_eco_k_f_veg_props[i] * c_eco_k_f_soilT * c_eco_k_f_soilW[i]
        tmp = clamp_zero_one(tmp)
        @rep_elem tmp ⇒ (c_eco_k, i)
    end

    ## pack land variables
    @pack_nt c_eco_k ⇒ land.diagnostics
    return land
end

purpose(::Type{cTau_mult}) = "Combines all effects that change the turnover rates by multiplication."

@doc """

$(getModelDocString(cTau_mult))

---

# Extended help

*References*

*Versions*
 - 1.0 on 12.01.2020 [sbesnard]  

*Created by*
 - ncarvalhais

*Notes:*
"""
cTau_mult
