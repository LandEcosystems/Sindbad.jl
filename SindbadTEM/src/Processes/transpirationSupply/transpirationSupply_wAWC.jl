export transpirationSupply_wAWC

#! format: off
@bounds @describe @units @timescale @with_kw struct transpirationSupply_wAWC{T1} <: transpirationSupply
    k_transpiration::T1 = 0.10 | (0.002, 0.99) | "fraction of total maximum available water that can be transpired" | "day-1" | "day"
end
#! format: on

function compute(params::transpirationSupply_wAWC, forcing, land, helpers)
    ## unpack parameters
    @unpack_transpirationSupply_wAWC params

    ## unpack land variables
    @unpack_nt PAW ⇐ land.states

    ## calculate variables
    transpiration_supply = sum(PAW) * k_transpiration

    ## pack land variables
    @pack_nt transpiration_supply ⇒ land.diagnostics
    return land
end

purpose(::Type{transpirationSupply_wAWC}) = "Supply-limited transpiration as the minimum of the fraction of total available water capacity and available moisture."

@doc """

$(getModelDocString(transpirationSupply_wAWC))

---

# Extended help

*References*
 - Teuling; 2007 | 2009: Time scales.#

*Versions*
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]
 - 1.1 on 02.11.2026 [skoirala | @dr-ko]: k_transpiration is a rate per day

*Created by*
 - skoirala | @dr-ko
"""
transpirationSupply_wAWC
