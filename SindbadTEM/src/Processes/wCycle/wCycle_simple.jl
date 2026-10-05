export wCycle_simple


struct wCycle_simple <: wCycle end

function define(params::wCycle_simple, forcing, land, helpers)
	return land
end

function precompute(params::wCycle_simple, forcing, land, helpers)
	return land
end

function compute(params::wCycle_simple, forcing, land, helpers)
    @unpack_nt begin
        (soilW, ΔsoilW) ⇐ land.pools
        zix ⇐ helpers.pools
    end
    total_water_prev = totalS(soilW)

    ## update variables
    soilW = addVec(soilW, ΔsoilW)

    # always pack land tws before calling the adjust method
    @pack_nt begin
        (soilW) ⇒ land.pools
    end


    # reset moisture changes to zero
    for l in eachindex(ΔsoilW)
        @rep_elem zero(eltype(ΔsoilW)) ⇒ (ΔsoilW, l)
    end

    total_water = totalS(soilW)

    ## pack land variables
    @pack_nt begin
        (ΔsoilW) ⇒ land.pools
        (total_water, total_water_prev) ⇒ land.states
    end
	return land
end

function update(params::wCycle_simple, forcing, land, helpers)
	return land
end

purpose(::Type{wCycle_simple}) = "update soilW assuming a simple model structure with only soilW pools"

@doc """ 

	$(getModelDocString(wCycle_simple))

---

# Extended help

*References*

*Versions*
 - 1.0 on 16.12.2025 [skoirala]

*Created by*
 - skoirala

"""
wCycle_simple

