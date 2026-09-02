export gppAirT_De2025

#! format: off
@bounds @describe @units @timescale @with_kw struct gppAirT_De2025{T1,T2,T3} <: gppAirT
	Topt::T1 = 10.0 | (5.0, 35.0) | "optimum air temperature" | "°C" | ""
	kT::T2 = 2.0 | (1.0, 20.0) | "temperature sensitivity scale" | "°C" | ""
	α::T3 = 0.29 | (0.0, 0.9) | "memory factor for filtered temperature" | "" | ""
end
#! format: on

function define(params::gppAirT_De2025, forcing, land, helpers)
	@unpack_nt f_airT_day ⇐ forcing

	## initialize filtered temperature with current temperature
	Tf_prev = f_airT_day

	## pack land variables
	@pack_nt Tf_prev ⇒ land.diagnostics
	return land
end

function precompute(params::gppAirT_De2025, forcing, land, helpers)
	@unpack_gppAirT_De2025 params
	@unpack_nt f_airT_day ⇐ forcing
	@unpack_nt Tf_prev ⇐ land.diagnostics
	@unpack_nt o_one ⇐ land.constants

	## initialize diagnostics
	gpp_f_airT = o_one

	## pack land variables
	@pack_nt gpp_f_airT ⇒ land.diagnostics
	return land
end

function compute(params::gppAirT_De2025, forcing, land, helpers)
	## unpack parameters and forcing
	@unpack_gppAirT_De2025 params
	@unpack_nt f_airT_day ⇐ forcing
	@unpack_nt Tf_prev ⇐ land.diagnostics
	@unpack_nt t_two ⇐ land.constants
	@unpack_nt gpp_f_airT ⇐ land.diagnostics

	## Horn temperature memory and response
	# T_f,k = (1 - α) * T_k + α * T_f,k-1
	Tf = (one(α) - α) * f_airT_day + α * Tf_prev

	# fT_Horn = 2 * exp(-(Tf - Topt)/kT) / (1 + exp(-(Tf - Topt)/kT))^2
	z = exp(-(Tf - Topt) / kT)
	denominator = one(Tf) + exp((-(Tf - Topt) / kT)) ^ t_two
	gpp_f_airT = clampZeroOne(t_two * z / denominator)

	## store T_f,k for next step as T_f,k-1
	Tf_prev = Tf

	## pack land variables
	@pack_nt (gpp_f_airT, Tf_prev) ⇒ land.diagnostics

	return land
end

# function update(params::gppAirT_De2025, forcing, land, helpers)
# 	return land
# end

purpose(::Type{gppAirT_De2025}) = "Using Ranit's corrected approach, i.e. 1 + exp(x) ^ 2 instead of 1 + exp(x^2)"

@doc """ 

	$(getModelDocString(gppAirT_De2025))

---

# Extended help

*References*
 - De, R., Bao, S., Koirala, S., Brenning, A., Reichstein, M., Tagesson, T., et al.: Addressing Challenges in Simulating Inter-Annual Variability of Gross Primary Production, Journal of Advances in Modeling Earth Systems, 17(5), e2024MS004697, https://doi.org/10.1029/2024MS004697, 2025.

*Versions*
 - 1.0 on 11.03.2026 [xshan]

*Created by*
 - xshan

"""
gppAirT_De2025

