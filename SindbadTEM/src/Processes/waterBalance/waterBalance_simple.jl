export waterBalance_simple

struct waterBalance_simple <: waterBalance end


function throwError(forcing, land, msg, water_balance, total_water, total_water_prev, WBP, precip, runoff, evapotranspiration)
    msg = "water balance error: $msg :: water_balance: $(water_balance), total_water: $(total_water), total_water_prev: $(total_water_prev), WBP: $(WBP), precip: $(precip), runoff: $(runoff), evapotranspiration: $(evapotranspiration)"
    @show land
    @show forcing
    println(msg)
    if hasproperty(SindbadTEM, :error_catcher)
        push!(SindbadTEM.error_catcher, land)
        push!(SindbadTEM.error_catcher, msg)
    end
    error(msg)
end
function checkWaterBalanceError(_, _, _, _, _, _, _, _, _, _, ::DoNotCatchModelErrors) # when catch_model_errors is false
    return nothing
end


function checkWaterBalanceError(forcing, land, water_balance, tolerance, total_water, total_water_prev, WBP, precip, runoff, evapotranspiration, ::DoCatchModelErrors) # when catch_model_errors is true
    if is_invalid_number(water_balance)
        throwError(forcing, land, "water balance is invalid", water_balance, total_water, total_water_prev, WBP, precip, runoff, evapotranspiration)
    end
    # Large stores such as snow on ice sheets cannot resolve storage changes finer than
    # the float spacing of total_water, so allow two spacings of rounding on top.
    wb_tolerance = tolerance + 2 * eps(max(abs(total_water), abs(total_water_prev)))
    if abs(water_balance) > wb_tolerance
        throwError(forcing, land, "water balance is larger than tolerance: $wb_tolerance", water_balance, total_water, total_water_prev, WBP, precip, runoff, evapotranspiration)
    end
    return nothing
end

function compute(params::waterBalance_simple, forcing, land, helpers)
    @unpack_nt begin
        precip ⇐ land.fluxes
        (total_water_prev, total_water, WBP) ⇐ land.states
        (evapotranspiration, runoff) ⇐ land.fluxes
        tolerance ⇐ helpers.numbers
    end

    ## calculate variables
    dS = total_water - total_water_prev
    water_balance = precip - runoff - evapotranspiration - dS

    checkWaterBalanceError(forcing, land, water_balance, tolerance, total_water, total_water_prev, WBP, precip, runoff, evapotranspiration, helpers.run.catch_model_errors)

    ## pack land variables
    @pack_nt water_balance ⇒ land.diagnostics
    return land
end

purpose(::Type{waterBalance_simple}) = "Simply checks the water balance as P-ET-R-ds/dt."

@doc """

$(getModelDocString(waterBalance_simple))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.11.2019
 - 1.1 on 20.11.2019 [skoirala | @dr-ko]:

*Created by*
 - skoirala | @dr-ko
"""
waterBalance_simple
