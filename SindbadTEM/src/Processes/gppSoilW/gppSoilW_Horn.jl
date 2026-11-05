export gppSoilW_Horn

#! format: off
@bounds @describe @units @timescale @with_kw struct gppSoilW_Horn{T1,T2,T3} <: gppSoilW
	kW::T1 = -11.0 | (-30.0, -5.0) | "sensitivity of GPP to soil moisture deficit" | "" | ""
	WI::T2 = 0.26 | (0.01, 0.99) | "inflection point of soil moisture response" | "" | ""
	α::T3 = 0.98 | (0.0, 1.0) | "memory factor for filtered soil moisture" | "" | ""
end
#! format: on

"""
	rootZoneWStressor(soilW, w_wp, w_awc, rooted_fraction)

Available water of the root zone normalized by its capacity, in [0, 1]. Each layer is
weighted by rooted_fraction.
"""
function rootZoneWStressor(soilW, w_wp, w_awc, rooted_fraction)
	max_AWC = sum(rooted_fraction .* w_awc)
	actAWC = sum(rooted_fraction .* at_least_zero.(soilW .- w_wp))
	return at_most_one(safe_divide(actAWC, max_AWC))
end

function define(params::gppSoilW_Horn, forcing, land, helpers)
	## unpack parameters and land
	@unpack_gppSoilW_Horn params
	@unpack_nt begin
		(w_awc, w_wp) ⇐ land.properties
		rooted_fraction ⇐ land.rootWaterEfficiency
		soilW ⇐ land.pools
	end

	## initialize filtered soil moisture with current normalized soil moisture
	Wf_prev = rootZoneWStressor(soilW, w_wp, w_awc, rooted_fraction)

	## pack land variables
	@pack_nt Wf_prev ⇒ land.diagnostics
	return land
end

function precompute(params::gppSoilW_Horn, forcing, land, helpers)
	return land
end

function compute(params::gppSoilW_Horn, forcing, land, helpers)
	@unpack_gppSoilW_Horn params

	@unpack_nt begin
		(w_awc, w_wp) ⇐ land.properties
		rooted_fraction ⇐ land.rootWaterEfficiency
		(soilW, ΔsoilW) ⇐ land.pools
		Wf_prev ⇐ land.diagnostics
	end

	Wk = rootZoneWStressor(soilW .+ ΔsoilW, w_wp, w_awc, rooted_fraction)

	## filtered soil moisture: W_f,k = (1 - α) * W_k + α * W_f,k-1
	Wf = (one(α) - α) * Wk + α * Wf_prev

	## Horn response: fW = 1 / (1 + exp(kW * (Wf - WI)))
	gpp_f_soilW = clamp_zero_one(one(kW) / (one(kW) + exp(kW * (Wf - WI))))

	## store W_f,k as W_f,k-1 for next timestep
	Wf_prev = Wf

	## pack land variables
	@pack_nt (gpp_f_soilW, Wf_prev) ⇒ land.diagnostics
	return land
end

# function update(params::gppSoilW_Horn, forcing, land, helpers)
# 	return land
# end

purpose(::Type{gppSoilW_Horn}) = "Soil moisture stress on GPP using Horn and Schulz (2011a) filtered-moisture sigmoid response."

@doc """ 

	$(getModelDocString(gppSoilW_Horn))

---

# Extended help

*References*

*Versions*
 - 1.0 on 10.03.2026 [xshan]
 - 1.1 on 02.11.2026 [skoirala | @dr-ko]: available water and its capacity over
   the root zone, each layer weighted by rooted_fraction, instead of the whole
   soil column. PAW is not used, as its root water efficiency of root carbon
   limits the extraction, which acts on GPP through transpiration_supply.

*Created by*
 - xshan

"""
gppSoilW_Horn

