export gppAirT_PHS

struct gppAirT_PHS <: gppAirT end

function define(params::gppAirT_PHS, forcing, land, helpers)
	@unpack_nt o_one ⇐ land.constants

	## initialize the response here, not in precompute. Precompute runs again at the
	## start of every run, and a reset to the Float32 o_one would change the type of
	## land there when the parameters are ForwardDiff.Dual. compute overwrites it
	## before it is read.
	gpp_f_airT = o_one

	## pack land variables
	@pack_nt (gpp_f_airT) ⇒ land.diagnostics
	return land
end

function compute(params::gppAirT_PHS, forcing, land, helpers)
	## unpack parameters and forcing
	@unpack_gppAirT_De2025 params

	@unpack_nt phs_f_temp ⇐ forcing

	gpp_f_airT = clamp_zero_one(phs_f_temp)

	## pack land variables
	@pack_nt (gpp_f_airT) ⇒ land.diagnostics

	return land
end

purpose(::Type{gppAirT_PHS}) = "use temperature response function from PHS. i.e., x * y / (x + y)"

@doc """ 

	$(getModelDocString(gppAirT_PHS))

---

# Extended help

*References*
 - Smallman, T.L., Williams, M., 2019. Description and validation of an intermediate complexity model for ecosystem photosynthesis and evapotranspiration: ACM-GPP-ETv1. Geoscientific Model Development 12, 2227–2253. https://doi.org/10.5194/gmd-12-2227-2019


*Versions*
 - 1.0 on 15.11.2026 [jzhou]

*Created by*
 - jzhou

"""
gppAirT_PHS