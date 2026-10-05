export wCycleBase_simple, adjustPackPoolComponents

#! format: off
struct wCycleBase_simple <: wCycleBase end
#! format: on

function define(params::wCycleBase_simple, forcing, land, helpers)
    w_model = params
    @pack_nt begin
        w_model ⇒ land.models
    end
    return land
end


function adjustPackPoolComponents(land, helpers, ::wCycleBase_simple)
    @unpack_nt TWS ⇐ land.pools
    zix = helpers.pools.zix
    if hasproperty(land.pools, :groundW)
        @unpack_nt groundW ⇐ land.pools
        for (lw, l) in enumerate(zix.groundW)
            @rep_elem TWS[l] ⇒ (groundW, lw)
        end
        @pack_nt groundW ⇒ land.pools
    end

    if hasproperty(land.pools, :snowW)
        @unpack_nt snowW ⇐ land.pools
        for (lw, l) in enumerate(zix.snowW)
            @rep_elem TWS[l] ⇒ (snowW, lw)
        end
        @pack_nt snowW ⇒ land.pools
    end

    if hasproperty(land.pools, :soilW)
        @unpack_nt soilW ⇐ land.pools
        for (lw, l) in enumerate(zix.soilW)
            @rep_elem TWS[l] ⇒ (soilW, lw)
        end
        @pack_nt soilW ⇒ land.pools
    end

    if hasproperty(land.pools, :surfaceW)
        @unpack_nt surfaceW ⇐ land.pools
        for (lw, l) in enumerate(zix.surfaceW)
            @rep_elem TWS[l] ⇒ (surfaceW, lw)
        end
        @pack_nt surfaceW ⇒ land.pools
    end

    return land
end

function adjustPackMainPool(land, helpers, ::wCycleBase_simple)
    @unpack_nt TWS ⇐ land.pools
    zix = helpers.pools.zix

    if hasproperty(land.pools, :groundW)
        @unpack_nt groundW ⇐ land.pools
        for (lw, l) in enumerate(zix.groundW)
            @rep_elem groundW[lw] ⇒ (TWS, l)
        end
    end

    if hasproperty(land.pools, :snowW)
        @unpack_nt snowW ⇐ land.pools
        for (lw, l) in enumerate(zix.snowW)
            @rep_elem snowW[lw] ⇒ (TWS, l)
        end
    end

    if hasproperty(land.pools, :soilW)
        @unpack_nt soilW ⇐ land.pools
        for (lw, l) in enumerate(zix.soilW)
            @rep_elem soilW[lw] ⇒ (TWS, l)
        end
    end

    if hasproperty(land.pools, :surfaceW)
        @unpack_nt surfaceW ⇐ land.pools
        for (lw, l) in enumerate(zix.surfaceW)
            @rep_elem surfaceW[lw] ⇒ (TWS, l)
        end
    end

    @pack_nt TWS ⇒ land.pools

    return land
end

purpose(::Type{wCycleBase_simple}) = "Through `wCycle`.jl, adjust/update the variables for each storage separately and for TWS."

@doc """

$(getModelDocString(wCycleBase_simple))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.07.2023 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko
"""
wCycleBase_simple
