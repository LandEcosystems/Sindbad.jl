export constants_numbers


@bounds @describe @units @timescale @with_kw struct constants_numbers{T1} <: constants 
    MJ_to_J::T1 = 1e6    | (-Inf, Inf) | "Convert from MJ to J" | "J/MJ" | ""
	J_to_MJ::T1 = 1e-6    | (-Inf, Inf) | "Convert from J to MJ" | "MJ/J" | ""
    d_to_s::T1 = 86400.0    | (-Inf, Inf) | "Convert from days to seconds" | "s/d" | ""
	const_tmelt::T1 = 273.15    | (-Inf, Inf) | "Temperature conversion" | "K" | ""
	Rd::T1 = 287.058    | (-Inf, Inf) | "Gas constant for dry air " | "(J/kg/K)" | ""
	Rho::T1 = 1.2250    | (-Inf, Inf) | "Standard sea level density of air  " | "(kg/m^3)" | ""
	epsilon::T1 = 0.622    | (-Inf, Inf) | "Ratio of molar masses (water/air)" | "" | ""
	const_rgas::T1 = 8.3144621    | (-Inf, Inf) | "Universal gas constant" | "(J/mol/K)" | ""
	mol_to_gC_day::T1 = 12.011 * 86400.0    | (-Inf, Inf) | "Scaling factor: (mol -> gC) * (sec -> day)" | "gC day-1" | ""

end

function define(params::constants_numbers, forcing, land, helpers)
	@unpack_constants_numbers params
	z_zero = oftype(helpers.numbers.tolerance, 0.0)
	o_one = oftype(helpers.numbers.tolerance, 1.0)
	t_two = oftype(helpers.numbers.tolerance, 2.0)
	t_three = oftype(helpers.numbers.tolerance, 3.0)

	@pack_nt (z_zero, o_one, t_two, t_three, MJ_to_J, d_to_s,J_to_MJ,const_tmelt,Rd,epsilon,const_rgas,mol_to_gC_day,Rho) ⇒ land.constants

	return land
end

purpose(::Type{constants_numbers}) = "Includes constants for numbers such as 1 to 10."

@doc """ 

	$(getModelDocString(constants_numbers))

---

# Extended help

*References*

*Versions*
 - 1.0 on 14.05.2025 [skoirala]

*Created by*
 - skoirala

"""
constants_numbers

