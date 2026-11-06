export evapotranspiration_simple

#! format: off
@bounds @describe @units @timescale @with_kw struct evapotranspiration_simple{T1, T2, T3} <: evapotranspiration
	k_evapotranspiration::T1 = 0.001 | (0.001, 0.10) | "evapotranspiration supplyrate" | "day-1" | "day"
	d_evapotranspiration::T2 = 0.01 | (0.001, 0.98) | "evapotranspiration demand rate" | "-" | "day"
	mj_to_mm::T3 = 2.45 | (-Inf, Inf) | "conversion factor from MJ to mm" | "MJ/mm" | ""
end
#! format: on

function define(params::evapotranspiration_simple, forcing, land, helpers)
	return land
end

function precompute(params::evapotranspiration_simple, forcing, land, helpers)
	return land
end

function compute(params::evapotranspiration_simple, forcing, land, helpers)
	@unpack_evapotranspiration_simple params
	@unpack_nt begin
		soilW ⇐ land.pools
		ΔsoilW ⇐ land.pools
		f_rn ⇐ forcing
	end
	evapotranspiration = min(k_evapotranspiration * (soilW[1] + ΔsoilW[1]), d_evapotranspiration * f_rn / mj_to_mm)
	@add_to_elem -evapotranspiration ⇒ (ΔsoilW, 1)
	@pack_nt begin
		evapotranspiration ⇒ land.fluxes
		ΔsoilW ⇒ land.pools
	end
	return land
end

function update(params::evapotranspiration_simple, forcing, land, helpers)
	return land
end

purpose(::Type{evapotranspiration_simple}) = "calculates evapotranspiration as a simple linear function of soil moisture"

@doc """ 

	$(getModelDocString(evapotranspiration_simple))

---

# Extended help

*References*

*Versions*
 - 1.0 on 16.12.2025 [skoirala]

*Created by*
 - skoirala

"""
evapotranspiration_simple

