export percolation_WBP

struct percolation_WBP <: percolation end

function compute(params::percolation_WBP, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        (ΔgroundW, ΔsoilW, soilW, groundW) ⇐ land.pools
        WBP ⇐ land.states
        o_one ⇐ land.constants
        n_groundW = groundW ⇐ helpers.pools.n_layers
        tolerance ⇐ helpers.numbers
        w_sat ⇐ land.properties
    end

    # set WBP as the soil percolation
    percolation = WBP
    to_allocate = o_one * percolation
    for sl ∈ eachindex(land.pools.soilW)
        allocated = min(w_sat[sl] - (soilW[sl] + ΔsoilW[sl]), to_allocate)
        @add_to_elem allocated ⇒ (ΔsoilW, sl)
        to_allocate = to_allocate - allocated
    end
    to_groundW = to_allocate / n_groundW
    ΔgroundW = addToEachElem(ΔgroundW, to_groundW)
    # to_groundW = abs(to_allocate)
    # ΔgroundW = addToEachElem(ΔgroundW, to_groundW / n_groundW)
    to_allocate = to_allocate - to_groundW
    WBP = to_allocate

    ## pack land variables
    @pack_nt begin
        percolation ⇒ land.fluxes
        WBP ⇒ land.states
        (ΔgroundW, ΔsoilW) ⇒ land.pools
    end
    return land
end

purpose(::Type{percolation_WBP}) = "Percolation as a difference of throughfall and surface runoff loss."

@doc """

$(getModelDocString(percolation_WBP))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.11.2019 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko
"""
percolation_WBP
