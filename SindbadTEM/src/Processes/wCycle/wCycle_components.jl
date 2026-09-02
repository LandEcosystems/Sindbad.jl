export wCycle_components

struct wCycle_components <: wCycle end


function compute(params::wCycle_components, forcing, land, helpers)
    ## unpack variables
    @unpack_nt begin
        (groundW, snowW, soilW, surfaceW, TWS) ⇐ land.pools
        (ΔgroundW, ΔsnowW, ΔsoilW, ΔsurfaceW, ΔTWS) ⇐ land.pools
        zix ⇐ helpers.pools
        (z_zero, o_one) ⇐ land.constants
        w_model ⇐ land.models
    end
    total_water_prev = totalS(soilW) + totalS(groundW) + totalS(surfaceW) + totalS(snowW)

    # @debug "wCycle_components"
    # @debug ΔsoilW

    ## update variables
    groundW = addVec(groundW, ΔgroundW)
    snowW = addVec(snowW, ΔsnowW)
    soilW = addVec(soilW, ΔsoilW)
    surfaceW = addVec(surfaceW, ΔsurfaceW)

    # setMainFromComponentPool(land, helpers, helpers.pools.vals.self.TWS, helpers.pools.vals.all_components.TWS, helpers.pools.vals.zix.TWS)

    # always pack land tws before calling the adjust method
    @pack_nt begin
        (groundW, snowW, soilW, surfaceW, TWS) ⇒ land.pools
    end

    land = adjustPackMainPool(land, helpers, w_model)

    # reset moisture changes to zero
    for l in eachindex(ΔsnowW)
        @rep_elem zero(eltype(ΔsnowW)) ⇒ (ΔsnowW, l, :snowW)
    end
    for l in eachindex(ΔsoilW)
        @rep_elem zero(eltype(ΔsoilW)) ⇒ (ΔsoilW, l, :soilW)
    end
    for l in eachindex(ΔgroundW)
        @rep_elem zero(eltype(ΔgroundW)) ⇒ (ΔgroundW, l, :groundW)
    end
    for l in eachindex(ΔsurfaceW)
        @rep_elem zero(eltype(ΔsurfaceW)) ⇒ (ΔsurfaceW, l, :surfaceW)
    end

    total_water = totalS(soilW) + totalS(groundW) + totalS(surfaceW) + totalS(snowW)

    ## pack land variables
    @pack_nt begin
        (ΔgroundW, ΔsnowW, ΔsoilW, ΔsurfaceW) ⇒ land.pools
        (total_water, total_water_prev) ⇒ land.states
    end
    return land
end

purpose(::Type{wCycle_components}) = "update the water cycle pools per component"

@doc """

$(getModelDocString(wCycle_components))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.11.2019 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko
"""
wCycle_components
