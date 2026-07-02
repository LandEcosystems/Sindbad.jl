export hydraulicConductivity_STEMMUS
export calculateDTheta, calculateDThetaLLh, calculateDTheta_LLh

#! format: off
@bounds @describe @units @timescale @with_kw struct hydraulicConductivity_STEMMUS{T1,T2,T3,T4,T5,T6,T7,T8} <: hydraulicConductivity
    hd::T1 = -1.0e7 | (-Inf, 0.0) | "Dry-end pressure head limit from STEMMUS_SCOPE soil constants" | "" | ""
    hm::T2 = -9899.0 | (-Inf, 0.0) | "Middle pressure head used by STEMMUS_SCOPE gamma-h formulation" | "" | ""
    head_tolerance::T3 = 1.0e-3 | (0.0, Inf) | "Tolerance for treating two pressure heads as equal" | "" | ""
    saturated_head_limit::T4 = -1.0 | (-Inf, 0.0) | "Pressure-head threshold for saturated conditions in the SWCC-SFCC branch" | "" | ""
    residual_theta_limit::T5 = 0.06 | (0.0, Inf) | "Lower liquid-water-content cutoff used when SFCC is disabled" | "" | ""
    swcc::T6 = 1 | (0, 1) | "Use the STEMMUS van Genuchten soil water characteristic curve branch" | "" | ""
    sfcc::T7 = 1 | (0, 1) | "Use the STEMMUS soil freezing characteristic curve branch" | "" | ""
    thmrlefc::T8 = 1 | (0, 1) | "Use thermally coupled liquid and frozen soil water capacity" | "" | ""
end
#! format: on

@inline _enabled(x) = x == true || x == 1
@inline _field(x, name::Symbol) = getproperty(x, name)

@inline function _field(x, primary::Symbol, fallback::Symbol)
    return hasproperty(x, primary) ? getproperty(x, primary) : getproperty(x, fallback)
end

@inline function _zero_dtheta(dtheta_uuh, theta_m, theta_uu, theta_ll, gamma_hh)
    return zero(dtheta_uuh + theta_m + theta_uu + theta_ll + gamma_hh)
end

@inline _at_index(x, i) = x isa AbstractArray ? x[i] : x

function define(params::hydraulicConductivity_STEMMUS, forcing, land, helpers)
    @unpack_nt soilW ⇐ land.pools

    dtheta_llh = zero(soilW)

    @pack_nt dtheta_llh ⇒ land.diagnostics
    return land
end

function compute(params::hydraulicConductivity_STEMMUS, forcing, land, helpers)
    @unpack_nt begin
        (dtheta_llh, dtheta_uuh, theta_m, theta_uu, theta_ll, gamma_hh) ⇐ land.diagnostics
        (stemmus_soil_variables, van_genuchten) ⇐ land.properties
    end

    for i in eachindex(dtheta_llh)
        tmp = _calculateDThetaLLh(
            params,
            _at_index(dtheta_uuh, i),
            _at_index(theta_m, i),
            _at_index(theta_uu, i),
            _at_index(theta_ll, i),
            _at_index(gamma_hh, i),
            _at_index(_field(stemmus_soil_variables, :Theta_U, :theta_u), i),
            _at_index(_field(stemmus_soil_variables, :hh), i),
            _at_index(_field(stemmus_soil_variables, :h), i),
            _at_index(_field(stemmus_soil_variables, :hh_frez), i),
            _at_index(_field(stemmus_soil_variables, :Phi_s, :phi_s), i),
            _at_index(_field(stemmus_soil_variables, :Lamda, :lamda), i),
            _at_index(_field(stemmus_soil_variables, :Theta_L, :theta_l), i),
            _at_index(_field(stemmus_soil_variables, :h_frez), i),
            _at_index(_field(van_genuchten, :Theta_s, :theta_s), i),
            _at_index(_field(van_genuchten, :Theta_r, :theta_r), i),
            _at_index(_field(van_genuchten, :Alpha, :alpha), i),
            _at_index(_field(van_genuchten, :n), i),
            _at_index(_field(van_genuchten, :m), i),
            params)
        @rep_elem tmp ⇒ (dtheta_llh, i, :soilW)
    end

    if dtheta_llh isa SVector
        @pack_nt dtheta_llh ⇒ land.diagnostics
    end
    return land
end

@inline function _calculateDTheta(
    ::Val{0},
    heat_term,
    theta_s,
    theta_r,
    theta_m,
    gamma_hh,
    theta_ll,
    theta_l,
    theta_uu,
    theta_u,
    hh,
    h,
    hh_frez,
    h_frez,
    phi_s,
    lamda,
    alpha,
    n,
    m,
    hd,
    hm)
    abs_alpha_heat = abs(alpha * heat_term)
    retention = (1 + abs_alpha_heat^n)^(-m)
    A = (-theta_r) / (abs(heat_term) * log(abs(hd / hm))) * (1 - retention)
    B = alpha * n * m * (theta_m - gamma_hh * theta_r)
    C = (1 + abs_alpha_heat^n)^(-m - 1)
    D = abs_alpha_heat^(n - 1)
    dtheta = A - B * C * D
    return hh + hh_frez <= hd ? zero(dtheta) : dtheta
end

@inline function _calculateDTheta(
    ::Val{1},
    heat_term,
    theta_s,
    theta_r,
    theta_m,
    gamma_hh,
    theta_ll,
    theta_l,
    theta_uu,
    theta_u,
    hh,
    h,
    hh_frez,
    h_frez,
    phi_s,
    lamda,
    alpha,
    n,
    m,
    hd,
    hm)
    A = (theta_m - theta_r) * alpha * n
    B = abs(alpha * heat_term)^(n - 1) * (-m)
    C = (1 + abs(alpha * heat_term)^n)^(-m - 1)
    return A * B * C
end

@inline function _calculateDTheta(
    ::Val{2},
    heat_term,
    theta_s,
    theta_r,
    theta_m,
    gamma_hh,
    theta_ll,
    theta_l,
    theta_uu,
    theta_u,
    hh,
    h,
    hh_frez,
    h_frez,
    phi_s,
    lamda,
    alpha,
    n,
    m,
    hd,
    hm)
    return (theta_ll - theta_l) / (hh + hh_frez - h - h_frez)
end

@inline function _calculateDTheta(
    ::Val{3},
    heat_term,
    theta_s,
    theta_r,
    theta_m,
    gamma_hh,
    theta_ll,
    theta_l,
    theta_uu,
    theta_u,
    hh,
    h,
    hh_frez,
    h_frez,
    phi_s,
    lamda,
    alpha,
    n,
    m,
    hd,
    hm)
    return (theta_uu - theta_u) / (hh - h)
end

@inline function _calculateDTheta(
    ::Val{4},
    heat_term,
    theta_s,
    theta_r,
    theta_m,
    gamma_hh,
    theta_ll,
    theta_l,
    theta_uu,
    theta_u,
    hh,
    h,
    hh_frez,
    h_frez,
    phi_s,
    lamda,
    alpha,
    n,
    m,
    hd,
    hm)
    return theta_s / phi_s * (hh / phi_s)^(-lamda - 1)
end

@inline function _calculateDTheta(
    ::Val{5},
    heat_term,
    theta_s,
    theta_r,
    theta_m,
    gamma_hh,
    theta_ll,
    theta_l,
    theta_uu,
    theta_u,
    hh,
    h,
    hh_frez,
    h_frez,
    phi_s,
    lamda,
    alpha,
    n,
    m,
    hd,
    hm)
    A = (theta_s - theta_r) * alpha * n
    B = abs(alpha * heat_term)^(n - 1) * (-m)
    C = (1 + abs(alpha * heat_term)^n)^(-m - 1)
    return A * B * C
end

"""
    calculateDTheta(params::hydraulicConductivity_STEMMUS, subroutine, heat_term, ...)

Port of STEMMUS_SCOPE `+conductivity/+hydraulicConductivity/calculateDTheta.m`.
The `Val`-specialized inner methods keep the branch formulas type-stable when
called from higher-level hydraulic-conductivity routines.
"""
function calculateDTheta(
    params::hydraulicConductivity_STEMMUS,
    subroutine::Integer,
    heat_term,
    theta_s,
    theta_r,
    theta_m,
    gamma_hh,
    theta_ll,
    theta_l,
    theta_uu,
    theta_u,
    hh,
    h,
    hh_frez,
    h_frez,
    phi_s,
    lamda,
    alpha,
    n,
    m)
    return _calculateDTheta(
        Val(subroutine),
        heat_term,
        theta_s,
        theta_r,
        theta_m,
        gamma_hh,
        theta_ll,
        theta_l,
        theta_uu,
        theta_u,
        hh,
        h,
        hh_frez,
        h_frez,
        phi_s,
        lamda,
        alpha,
        n,
        m,
        params.hd,
        params.hm)
end

calculateDTheta(subroutine::Integer, args...) = calculateDTheta(hydraulicConductivity_STEMMUS(), subroutine, args...)

@inline function _calculateDThetaLLh(
    params::hydraulicConductivity_STEMMUS,
    dtheta_uuh,
    theta_m,
    theta_uu,
    theta_ll,
    gamma_hh,
    theta_u,
    hh,
    h,
    hh_frez,
    phi_s,
    lamda,
    theta_l,
    h_frez,
    theta_s,
    theta_r,
    alpha,
    n,
    m,
    model_settings)
    heat_term = hh + hh_frez
    swcc = _enabled(_field(model_settings, :SWCC, :swcc))
    sfcc = _enabled(_field(model_settings, :SFCC, :sfcc))
    thmrlefc = _enabled(_field(model_settings, :Thmrlefc, :thmrlefc))
    z_dtheta = _zero_dtheta(dtheta_uuh, theta_m, theta_uu, theta_ll, gamma_hh)

    if swcc
        if sfcc
            if hh >= params.saturated_head_limit
                return z_dtheta
            elseif thmrlefc
                if gamma_hh == zero(gamma_hh)
                    return z_dtheta
                end
                return _calculateDTheta(
                    Val(0),
                    hh,
                    theta_s,
                    theta_r,
                    theta_m,
                    gamma_hh,
                    theta_ll,
                    theta_l,
                    theta_uu,
                    theta_u,
                    hh,
                    h,
                    hh_frez,
                    h_frez,
                    phi_s,
                    lamda,
                    alpha,
                    n,
                    m,
                    params.hd,
                    params.hm)
            elseif abs(hh - h) < params.head_tolerance
                return _calculateDTheta(
                    Val(1),
                    hh,
                    theta_s,
                    theta_r,
                    theta_m,
                    gamma_hh,
                    theta_ll,
                    theta_l,
                    theta_uu,
                    theta_u,
                    hh,
                    h,
                    hh_frez,
                    h_frez,
                    phi_s,
                    lamda,
                    alpha,
                    n,
                    m,
                    params.hd,
                    params.hm)
            else
                return _calculateDTheta(
                    Val(3),
                    hh,
                    theta_s,
                    theta_r,
                    theta_m,
                    gamma_hh,
                    theta_ll,
                    theta_l,
                    theta_uu,
                    theta_u,
                    hh,
                    h,
                    hh_frez,
                    h_frez,
                    phi_s,
                    lamda,
                    alpha,
                    n,
                    m,
                    params.hd,
                    params.hm)
            end
        elseif hh <= params.hd || theta_ll <= params.residual_theta_limit
            return z_dtheta
        else
            return dtheta_uuh
        end
    else
        if hh <= params.hd || heat_term <= params.hd || heat_term >= phi_s
            return z_dtheta
        elseif thmrlefc
            return _calculateDTheta(
                Val(4),
                heat_term,
                theta_s,
                theta_r,
                theta_m,
                gamma_hh,
                theta_ll,
                theta_l,
                theta_uu,
                theta_u,
                hh,
                h,
                hh_frez,
                h_frez,
                phi_s,
                lamda,
                alpha,
                n,
                m,
                params.hd,
                params.hm)
        elseif abs(hh - h) < params.head_tolerance
            return _calculateDTheta(
                Val(5),
                heat_term,
                theta_s,
                theta_r,
                theta_m,
                gamma_hh,
                theta_ll,
                theta_l,
                theta_uu,
                theta_u,
                hh,
                h,
                hh_frez,
                h_frez,
                phi_s,
                lamda,
                alpha,
                n,
                m,
                params.hd,
                params.hm)
        else
            return _calculateDTheta(
                Val(2),
                heat_term,
                theta_s,
                theta_r,
                theta_m,
                gamma_hh,
                theta_ll,
                theta_l,
                theta_uu,
                theta_u,
                hh,
                h,
                hh_frez,
                h_frez,
                phi_s,
                lamda,
                alpha,
                n,
                m,
                params.hd,
                params.hm)
        end
    end
end

"""
    calculateDThetaLLh(params::hydraulicConductivity_STEMMUS, dtheta_uuh, theta_m, theta_uu, theta_ll, gamma_hh, soil, vg, settings)

Port of STEMMUS_SCOPE `calculateDTheta_LLh.m`.

The wrapper accepts the original STEMMUS-style field names (`Theta_U`,
`Theta_s`, `SWCC`, ...). Lower-case `theta_*` Van Genuchten aliases are also
accepted where they are common in Julia code.
"""
function calculateDThetaLLh(
    params::hydraulicConductivity_STEMMUS,
    dtheta_uuh,
    theta_m,
    theta_uu,
    theta_ll,
    gamma_hh,
    soil_variables,
    van_genuchten,
    model_settings)
    theta_s = _field(van_genuchten, :Theta_s, :theta_s)
    theta_r = _field(van_genuchten, :Theta_r, :theta_r)
    alpha = _field(van_genuchten, :Alpha, :alpha)
    n = _field(van_genuchten, :n)
    m = _field(van_genuchten, :m)

    theta_u = _field(soil_variables, :Theta_U, :theta_u)
    hh = _field(soil_variables, :hh)
    h = _field(soil_variables, :h)
    hh_frez = _field(soil_variables, :hh_frez)
    phi_s = _field(soil_variables, :Phi_s, :phi_s)
    lamda = _field(soil_variables, :Lamda, :lamda)
    theta_l = _field(soil_variables, :Theta_L, :theta_l)
    h_frez = _field(soil_variables, :h_frez)

    return _calculateDThetaLLh(
        params,
        dtheta_uuh,
        theta_m,
        theta_uu,
        theta_ll,
        gamma_hh,
        theta_u,
        hh,
        h,
        hh_frez,
        phi_s,
        lamda,
        theta_l,
        h_frez,
        theta_s,
        theta_r,
        alpha,
        n,
        m,
        model_settings)
end

function calculateDThetaLLh(dtheta_uuh, theta_m, theta_uu, theta_ll, gamma_hh, soil_variables, van_genuchten, model_settings)
    return calculateDThetaLLh(
        hydraulicConductivity_STEMMUS(),
        dtheta_uuh,
        theta_m,
        theta_uu,
        theta_ll,
        gamma_hh,
        soil_variables,
        van_genuchten,
        model_settings)
end

calculateDTheta_LLh(args...) = calculateDThetaLLh(args...)

purpose(::Type{hydraulicConductivity_STEMMUS}) = "STEMMUS_SCOPE hydraulic-conductivity helper functions for soil water retention and frozen-soil coupling."

@doc """

$(getModelDocString(hydraulicConductivity_STEMMUS))

---

# Extended help

*References*
 - Ported from STEMMUS_SCOPE `+conductivity/+hydraulicConductivity/calculateDTheta.m`
   and `calculateDTheta_LLh.m`.

*Versions*
 - 1.0 on 18.05.2026 [jzhou]: initial SINDBAD-style port of the STEMMUS_SCOPE derivative helper.

*Created by*
 - jzhou
"""
hydraulicConductivity_STEMMUS
