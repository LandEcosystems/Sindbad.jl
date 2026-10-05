export vegAvailableWater_sigmoid

#! format: off
@bounds @describe @units @timescale @with_kw struct vegAvailableWater_sigmoid{T1} <: vegAvailableWater
    exp_factor::T1 = 1.0 | (0.02, 3.0) | "multiplier of B factor of exponential rate" | "" | ""
end
#! format: on

function define(params::vegAvailableWater_sigmoid, forcing, land, helpers)
    ## unpack parameters
    @unpack_vegAvailableWater_sigmoid params

    ## unpack land variables
    @unpack_nt begin
        soilW ⇐ land.pools
    end

    θ_dos = zero(soilW)
    θ_fc_dos = zero(soilW)
    PAW = zero(soilW)
    soilW_stress = zero(soilW)
    max_water = zero(soilW)

    ## pack land variables
    @pack_nt (θ_dos, θ_fc_dos, PAW, soilW_stress, max_water) ⇒ land.states
    return land
end

function compute(params::vegAvailableWater_sigmoid, forcing, land, helpers)
    ## unpack parameters
    @unpack_vegAvailableWater_sigmoid params

    ## unpack land variables
    @unpack_nt begin
        (w_wp, w_fc, w_sat, soil_β) ⇐ land.properties
        root_water_efficiency ⇐ land.diagnostics
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        (θ_dos, θ_fc_dos, PAW, soilW_stress, max_water) ⇐ land.states
        (z_zero, o_one) ⇐ land.constants
    end
    for sl ∈ eachindex(soilW)
        θ_dos = (soilW[sl] + ΔsoilW[sl]) / w_sat[sl]
        θ_fc_dos = w_fc[sl] / w_sat[sl]
        tmp_soilW_stress = clamp_zero_one(o_one / (o_one + exp(-exp_factor * soil_β[sl] * (θ_dos - θ_fc_dos))))
        @rep_elem tmp_soilW_stress ⇒ (soilW_stress, sl)
        max_water = clamp_zero_one(soilW[sl] + ΔsoilW[sl] - w_wp[sl])
        PAW_sl = root_water_efficiency[sl] * max_water * tmp_soilW_stress
        @rep_elem PAW_sl ⇒ (PAW, sl)
    end

    ## pack land variables
    @pack_nt (PAW, soilW_stress) ⇒ land.states
    return land
end

purpose(::Type{vegAvailableWater_sigmoid}) = "PAW using a sigmoid function of soil moisture."

@doc """

$(getModelDocString(vegAvailableWater_sigmoid))

---

# Extended help

*References*

*Versions*
 - 1.0 on 21.11.2019  

*Created by*
 - skoirala | @dr-ko
"""
vegAvailableWater_sigmoid
