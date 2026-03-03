export gpp_JSBACH

#! format: off
@bounds @describe @units @timescale @with_kw struct gpp_JSBACH{T1,T2,T3,T4,T5} <: gpp
	P1::T1 = 0.2 | (-Inf, Inf) | "parameter 1" | "parameter 1 unit" | "parameter 1 timescale"
	P2::T2 = Inf | (-Inf, Inf) | "parameter 2" | "parameter 2 unit" | "parameter 2 timescale"
	P3::T3 = Inf | (-Inf, Inf) | "parameter 3" | "parameter 3 unit" | "parameter 3 timescale"
	P4::T4 = Inf | (-Inf, Inf) | "parameter 4" | "parameter 4 unit" | "parameter 4 timescale"
	P5::T5 = Inf | (-Inf, Inf) | "parameter 5" | "parameter 5 unit" | "parameter 5 timescale"
end
#! format: on

function define(params::gpp_JSBACH, forcing, land, helpers)
	return land
end

function precompute(params::gpp_JSBACH, forcing, land, helpers)
	return land
end

function compute(params::gpp_JSBACH, forcing, land, helpers)
	## Automatically generated sample code for basis. Modify, correct, and use. define, precompute, and update methods can use similar coding when needed. When not, they can simply be deleted. 
	@unpack_gpp_JSBACH params # unpack the model parameters
	## unpack NT forcing
	# @unpack_nt f_variable ⇐ forcing
	gpp = P1
	## unpack NT land
	# @unpack_nt begin
		# flux_variable ⇐ land.fluxes
		# state_variable ⇐ land.states
	# end

	## Do calculations

	## pack land variables
	@pack_nt gpp ⇒ land.fluxes

	return land
end

function update(params::gpp_JSBACH, forcing, land, helpers)
	return land
end

purpose(::Type{gpp_JSBACH}) = "Calculate GPP based on JSBACH"

@doc """ 

	$(getModelDocString(gpp_JSBACH))

---

# Extended help

*References*

*Versions*
 - 1.0 on 03.03.2026 [skoirala]

*Created by*
 - skoirala

"""
gpp_JSBACH

