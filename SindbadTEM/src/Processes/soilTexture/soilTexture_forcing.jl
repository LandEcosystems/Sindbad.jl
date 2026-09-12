export soilTexture_forcing

struct soilTexture_forcing <: soilTexture end

function define(params::soilTexture_forcing, forcing, land, helpers)
    ## unpack forcing
    @unpack_nt soilW ⇐ land.pools

    ## precomputations/check
    st_clay = zero(soilW)
    st_orgm = zero(soilW)
    st_sand = zero(soilW)
    st_silt = zero(soilW)

    ## pack land variables
    @pack_nt (st_clay, st_orgm, st_sand, st_silt) ⇒ land.properties
    return land
end


function precompute(params::soilTexture_forcing, forcing, land, helpers)
    ## unpack variables
    @unpack_nt (f_clay, f_orgm, f_sand, f_silt) ⇐ forcing
    @unpack_nt (st_clay, st_orgm, st_sand, st_silt) ⇐ land.properties

    if length(f_clay) != length(st_clay)
        @debug "soilTexture_forcing: the number of soil layers in forcing data does not match the layers in model_structure.json. Using mean of input over the soil layers."
        for sl ∈ eachindex(st_clay)
            @rep_elem mean(f_clay) ⇒ (st_clay, sl)
            @rep_elem mean(f_sand) ⇒ (st_sand, sl)
            @rep_elem mean(f_silt) ⇒ (st_silt, sl)
            @rep_elem mean(f_orgm) ⇒ (st_orgm, sl)
        end
    else
        for sl ∈ eachindex(st_clay)
            @rep_elem f_clay[sl] ⇒ (st_clay, sl)
            @rep_elem f_sand[sl] ⇒ (st_sand, sl)
            @rep_elem f_silt[sl] ⇒ (st_silt, sl)
            @rep_elem f_orgm[sl] ⇒ (st_orgm, sl)
        end
    end
    ## pack land variables
    @pack_nt (st_clay, st_orgm, st_sand, st_silt) ⇒ land.properties
    return land
end

purpose(::Type{soilTexture_forcing}) = "Gets Soil texture properties from forcing data."

@doc """

$(getModelDocString(soilTexture_forcing))

---

# Extended help

*References*

*Versions*
 - 1.0 on 21.11.2019  

*Created by*
 - skoirala | @dr-ko

*Notes*
 - if not; then sets the average of all as the fixed property of all layers
 - if the input has same number of layers & soilW; then sets the properties per layer
"""
soilTexture_forcing
