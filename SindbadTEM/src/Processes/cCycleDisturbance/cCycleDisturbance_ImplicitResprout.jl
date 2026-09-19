export cCycleDisturbance_ImplicitResprout

#! format: off
@bounds @describe @units @timescale @with_kw struct cCycleDisturbance_ImplicitResprout{T1} <: cCycleDisturbance
    frac_reserve_survival::T1 = 1.0 | (0.0, 1.0) | "fraction of the reserve carbon pools that survives upon a disturbance" | "" | ""
end
#! format: on

function define(params::cCycleDisturbance_ImplicitResprout, forcing, land, helpers)
    @unpack_nt begin
        (c_flow_order, c_giver, c_taker) ⇐ land.cCycleBase
        cVeg ⇐ land.pools
    end
    zix_veg_all = Tuple(vcat(getZix(cVeg, helpers.pools.zix.cVeg)...))
    c_lose_to_zix_vec = Tuple{Vararg{Int}}[]
    for zixVeg ∈ zix_veg_all
        ndxNoVeg = Int[]
        for j ∈ c_flow_order
            if c_giver[j] == zixVeg && !(c_taker[j] ∈ zix_veg_all)
                push!(ndxNoVeg, c_taker[j])
            end
        end
        push!(c_lose_to_zix_vec, Tuple(ndxNoVeg))
    end
    c_lose_to_zix_vec = Tuple(c_lose_to_zix_vec)
    @pack_nt (zix_veg_all, c_lose_to_zix_vec) ⇒ land.cCycleDisturbance
    return land
end

function compute(params::cCycleDisturbance_ImplicitResprout, forcing, land, helpers)
    ## unpack forcing
    @unpack_nt f_dist_intensity ⇐ forcing
    @unpack_cCycleDisturbance_ImplicitResprout params

    ## unpack land variables
    @unpack_nt begin
        (zix_veg_all, c_lose_to_zix_vec) ⇐ land.cCycleDisturbance
        cEco ⇐ land.pools
        z_zero ⇐ land.constants
        c_remain ⇐ land.states
        c_model ⇐ land.models
    end
    if f_dist_intensity > z_zero
        for (iVeg, zixVeg) ∈ pairs(zix_veg_all)
            cLoss = at_least_zero(cEco[zixVeg] - c_remain * (frac_reserve_survival > 0)) * f_dist_intensity * 
                (helpers.pools.components.cEco[zixVeg] === :cVegReserve ? 
                    one(frac_reserve_survival) - frac_reserve_survival : 
                    one(frac_reserve_survival))
            @add_to_elem -cLoss ⇒ (cEco, zixVeg, :cEco)
            c_lose_to_zix = c_lose_to_zix_vec[iVeg]
            for tZ ∈ eachindex(c_lose_to_zix)
                tarZix = c_lose_to_zix[tZ]
                toGain = cLoss / oftype(cLoss, length(c_lose_to_zix))
                @add_to_elem toGain ⇒ (cEco, tarZix, :cEco)
            end
        end
        @pack_nt cEco ⇒ land.pools
        land = adjustPackPoolComponents(land, helpers, c_model)
    end
    ## pack land variables
    return land
end

purpose(::Type{cCycleDisturbance_ImplicitResprout}) = "Moves carbon in vegetation pools to their non-vegetation carbon-flow target pools during disturbance events while allowing a parameterized fraction of the reserve pool to survive."

@doc """

$(getModelDocString(cCycleDisturbance_ImplicitResprout))

---

# Extended help

This approach is called `ImplicitResprout` because post-disturbance recovery is represented 
implicitly through survival of a fraction `frac_reserve_survival` of `cVegReserve`, rather 
than through an explicit resprouting via seed pools. The non-surviving fraction follows the 
existing vegetation-to-litter flow pathways. `frac_reserve_survival = 0` reduces to 
`NoRecovery` for the reserve pool, while `frac_reserve_survival = 1` gives complete reserve 
survival.

*References*
 - Carvalhais; N.; Reichstein; M.; Seixas; J.; Collatz; G. J.; Pereira; J. S.; Berbigier; P.  & Rambal, S. (2008). Implications of the carbon cycle steady state assumption for  biogeochemical modeling performance & inverse parameter retrieval. Global Biogeochemical Cycles, 22[2].

*Versions*
 - 1.0 on 23.04.2021 [skoirala | @dr-ko]
 - 1.0 on 23.04.2021 [skoirala | @dr-ko]  
 - 1.1 on 29.11.2021 [skoirala | @dr-ko]: moved the scaling parameters to  ccyclebase_gsi [land.diagnostics.ηA & land.diagnostics.ηH]  

*Created by*
 - skoirala | @dr-ko
"""
cCycleDisturbance_ImplicitResprout
