export constants_numbers


@bounds @describe @units @timescale @with_kw struct constants_numbers{T1} <: constants 
    MJ_to_J::T1 = 1e6    | (-Inf, Inf) | "Minimum LAI for numerical stability" | "m2 m⁻2" | ""
    d_to_s::T1 = 86400.0    | (-Inf, Inf) | "Minimum LAI for numerical stability" | "m2 m⁻2" | ""
end

function define(params::constants_numbers, forcing, land, helpers)
	@unpack_constants_numbers params
	z_zero = oftype(helpers.numbers.tolerance, 0.0)
	o_one = oftype(helpers.numbers.tolerance, 1.0)
	t_two = oftype(helpers.numbers.tolerance, 2.0)
	t_three = oftype(helpers.numbers.tolerance, 3.0)

	@pack_nt (z_zero, o_one, t_two, t_three, MJ_to_J, d_to_s) ⇒ land.constants

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

