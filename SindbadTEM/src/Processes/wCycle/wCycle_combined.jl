export wCycle_combined

struct wCycle_combined <: wCycle end

function checkTWSError(TWS, tolerance, ::DoNotCatchModelErrors) # when catch_model_errors is false
    return TWS
end

function checkTWSError(TWS, tolerance, ::DoCatchModelErrors) # when catch_model_errors is true
    if minimum(TWS) < zero(eltype(TWS))
        if abs(minimum(TWS)) < tolerance
            @error "Numerically small negative TWS ($(TWS)) smaller than tolerance ($(tolerance)) were replaced with absolute value of the storage"
            TWS = abs.(TWS)
        else
            error("TWS is negative. Cannot continue. $(TWS)")
        end
    end
    return TWS
end

function define(params::wCycle_combined, forcing, land, helpers)
    ## unpack variables
    @unpack_nt begin
        ΔTWS ⇐ land.pools
    end
    zeroΔTWS = zero(ΔTWS)

    @pack_nt zeroΔTWS ⇒ land.pools
    return land
end

function compute(params::wCycle_combined, forcing, land, helpers)
    ## unpack variables
    @unpack_nt begin
        TWS ⇐ land.pools
        (ΔTWS, zeroΔTWS) ⇐ land.pools
        tolerance ⇐ helpers.numbers
        (z_zero, o_one) ⇐ land.constants
    end
    total_water_prev = sum(TWS)
    #TWS_old = deepcopy(TWS)
    ## update variables
    TWS = addVec(TWS, ΔTWS)

    # reset soil moisture changes to zero
    TWS = checkTWSError(TWS, tolerance, helpers.run.catch_model_errors)
    ΔTWS = zeroΔTWS

    total_water = sum(TWS)

    # pack land variables
    @pack_nt begin
        (ΔTWS, TWS) ⇒ land.pools
        (total_water, total_water_prev) ⇒ land.states
    end
    return land
end

purpose(::Type{wCycle_combined}) = "computes the algebraic sum of storage and delta storage"

@doc """

$(getModelDocString(wCycle_combined))

---

# Extended help

*References*

*Versions*
 - 1.0 on 18.11.2019 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko
"""
wCycle_combined
