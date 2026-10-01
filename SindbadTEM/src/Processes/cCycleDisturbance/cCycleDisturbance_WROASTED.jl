export cCycleDisturbance_WROASTED

#! format: off
struct cCycleDisturbance_WROASTED <: cCycleDisturbance end
#! format: on

function define(params::cCycleDisturbance_WROASTED, forcing, land, helpers)
    @unpack_nt begin
        (c_giver, c_taker) ⇐ land.constants
        cVeg ⇐ land.pools
    end
    zix_veg_all = Tuple(vcat(getZix(cVeg, helpers.pools.zix.cVeg)...))
    c_lose_to_zix_vec = Tuple{Int}[]
    for zixVeg ∈ zix_veg_all
        # make reserve pool flow to slow litter pool/woody debris
        if helpers.pools.components.cEco[zixVeg] == :cVegReserve
            c_lose_to_zix = helpers.pools.zix.cLitSlow
        else
            c_lose_to_zix = c_taker[[(c_giver .== zixVeg)...]]
        end
        ndxNoVeg = Int[]
        for ndxl ∈ c_lose_to_zix
            if ndxl ∉ zix_veg_all
                push!(ndxNoVeg, ndxl)
            end
        end
        push!(c_lose_to_zix_vec, Tuple(ndxNoVeg))
    end
    c_lose_to_zix_vec = Tuple(c_lose_to_zix_vec)
    @pack_nt (zix_veg_all, c_lose_to_zix_vec) ⇒ land.cCycleDisturbance
    return land
end

function compute(params::cCycleDisturbance_WROASTED, forcing, land, helpers)
    ## unpack forcing
    @unpack_nt f_dist_intensity ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        (zix_veg_all, c_lose_to_zix_vec) ⇐ land.cCycleDisturbance
        cEco ⇐ land.pools
        (c_giver, c_taker) ⇐ land.constants
        c_remain ⇐ land.states
        c_model ⇐ land.models
    end
    for zixVeg ∈ zix_veg_all
        cLoss = at_least_zero(cEco[zixVeg] - c_remain) * f_dist_intensity
        @add_to_elem -cLoss ⇒ (cEco, zixVeg, :cEco)
        c_lose_to_zix = c_lose_to_zix_vec[zixVeg]
        for tZ ∈ eachindex(c_lose_to_zix)
            tarZix = c_lose_to_zix[tZ]
            toGain = cLoss / oftype(cLoss, length(c_lose_to_zix))
            @add_to_elem toGain ⇒ (cEco, tarZix, :cEco)
        end
    end
    @pack_nt cEco ⇒ land.pools
    land = adjustPackPoolComponents(land, helpers, c_model)
    ## pack land variables
    return land
end

purpose(::Type{cCycleDisturbance_WROASTED}) = "Moves carbon in reserve pool to slow litter pool, and all other carbon pools except reserve pool to their respective carbon flow target pools during disturbance events."

@doc """

$(getModelDocString(cCycleDisturbance_WROASTED))

---

# Extended help

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].

*Versions*
 - 1.0 on 23.04.2021 [skoirala | @dr-ko]
 - 1.0 on 23.04.2021 [skoirala | @dr-ko]  
 - 1.1 on 29.11.2021 [skoirala | @dr-ko]: moved the scaling parameters to  ccyclebase_gsi [land.diagnostics.ηA & land.diagnostics.ηH]  

*Created by*
 - skoirala | @dr-ko
"""
cCycleDisturbance_WROASTED
