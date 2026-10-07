export wCycle_combined

struct wCycle_combined <: wCycle end

function define(params::wCycle_combined, forcing, land, helpers)
    ## unpack variables
    @unpack_nt begin
        ΔTWS ⇐ land.pools
    end
    zeroΔTWS = zero(ΔTWS)

    @pack_nt zeroΔTWS ⇒ land.pools
    return land
end

# kept out of compute so that the message formatting does not bloat the hot function
@noinline function printSmallNegativeTWS(TWS, tolerance)
    print_info(nothing, @__FILE__, @__LINE__, "Numerically small negative TWS ($(TWS)) smaller than tolerance ($(tolerance)) were replaced with absolute value of the storage", n_m=4)
    return nothing
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
    if minimum(TWS) < z_zero
        if abs(minimum(TWS)) < tolerance
            printSmallNegativeTWS(TWS, tolerance)
            # @assert(false, "Numerically small negative TWS ($(TWS)) smaller than tolerance ($(tolerance)) were replaced with absolute value of the storage") 
            TWS = abs.(TWS)
        else
            error("TWS is negative. Cannot continue. $(TWS)")
        end
    end
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
