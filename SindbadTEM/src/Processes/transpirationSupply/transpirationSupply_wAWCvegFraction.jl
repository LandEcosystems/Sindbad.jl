export transpirationSupply_wAWCvegFraction

#! format: off
@bounds @describe @units @timescale @with_kw struct transpirationSupply_wAWCvegFraction{T1} <: transpirationSupply
    k_transpiration::T1 = 0.10 | (0.002, 0.99) | "fraction of total maximum available water that can be transpired" | "day-1" | "day"
end
#! format: on

function compute(params::transpirationSupply_wAWCvegFraction, forcing, land, helpers)
    ## unpack parameters
    @unpack_transpirationSupply_wAWCvegFraction params

    ## unpack land variables
    @unpack_nt (PAW, frac_vegetation) ⇐ land.states

    ## calculate variables
    transpiration_supply = sum(PAW) * k_transpiration * frac_vegetation

    ## pack land variables
    @pack_nt transpiration_supply ⇒ land.diagnostics
    return land
end

purpose(::Type{transpirationSupply_wAWCvegFraction}) = "Supply-limited transpiration as the minimum of the fraction of total available water capacity and available moisture, scaled by vegetated fractions."

@doc """

$(getModelDocString(transpirationSupply_wAWCvegFraction))

---

# Extended help

*References*

*Versions*
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko

*Notes*
 - Assumes that the transpiration supply scales with vegetated fraction
"""
transpirationSupply_wAWCvegFraction
