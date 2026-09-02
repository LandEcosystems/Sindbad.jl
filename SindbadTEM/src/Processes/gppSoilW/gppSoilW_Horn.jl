export gppSoilW_Horn

#! format: off
@bounds @describe @units @timescale @with_kw struct gppSoilW_Horn{T1,T2,T3} <: gppSoilW
	kW::T1 = -11.0 | (-30.0, -5.0) | "sensitivity of GPP to soil moisture deficit" | "" | ""
	WI::T2 = 0.26 | (0.01, 0.99) | "inflection point of soil moisture response" | "" | ""
	α::T3 = 0.98 | (0.0, 1.0) | "memory factor for filtered soil moisture" | "" | ""
end
#! format: on

function define(params::gppSoilW_Horn, forcing, land, helpers)
	## unpack parameters and land
	@unpack_gppSoilW_Horn params
	@unpack_nt begin
		(∑w_fc, ∑w_wp) ⇐ land.properties
		soilW ⇐ land.pools
	end

	## initialize filtered soil moisture with current normalized soil moisture
	SM = sum(soilW)
	max_AWC = maxZero(∑w_fc - ∑w_wp)
	actAWC = maxZero(SM - ∑w_wp)
	Wf_prev = minOne(actAWC / max_AWC)

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
		(∑w_fc, ∑w_wp) ⇐ land.properties
		soilW ⇐ land.pools
		Wf_prev ⇐ land.diagnostics
	end

	## normalize soil moisture: W_k in [0, 1]
	SM = sum(soilW)
	max_AWC = maxZero(∑w_fc - ∑w_wp)
	actAWC = maxZero(SM - ∑w_wp)
	Wk = minOne(actAWC / max_AWC)

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

*Created by*
 - xshan

"""
gppSoilW_Horn

