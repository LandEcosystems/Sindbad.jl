import NonlinearSolve as NLS
using StaticArrays: SVector

# Numerical solver for the coupled PHS equilibrium. Process equations and
# physical units remain in plantHydraulics_PHS.jl. This file only maps the
# constrained physical state to smooth, dimensionless solver coordinates and
# calls NonlinearSolve.jl.

const _PHS_COUPLED_MAX_ITERATIONS = 100

@inline _phs_norm5(values) = maximum(abs, values)
@inline _phs_merit(values) = sum(abs2, values) / 2

@inline function _phs_coupled_result(
    solution,
    status::Symbol,
    converged::Bool,
    iterations::Int,
    residual_norm,
    damping,
    lm_lambda;
    objective=residual_norm * residual_norm / 2,
    function_evaluations::Int=0,
    fallback_steps::Int=0,
    restarts::Int=0,
    trust_radius=zero(residual_norm),
    used_lm::Bool=lm_lambda > zero(lm_lambda),
    retcode=nothing,
    jacobian_evaluations::Int=0,
    linear_solves::Int=0,
)
    return (
        solution=solution,
        status=status,
        converged=converged,
        iterations=iterations,
        residual_norm=residual_norm,
        objective=objective,
        accepted_damping=damping,
        lm_lambda=lm_lambda,
        used_lm=used_lm,
        function_evaluations=function_evaluations,
        fallback_steps=fallback_steps,
        restarts=restarts,
        trust_radius=trust_radius,
        retcode=retcode,
        jacobian_evaluations=jacobian_evaluations,
        linear_solves=linear_solves,
    )
end

@inline function _phs_softplus(value)
    return max(value, zero(value)) + log1p(exp(-abs(value)))
end

@inline function _phs_inverse_softplus(value)
    threshold = oftype(value, 20)
    return value > threshold ? value : log(expm1(value))
end

@inline function _phs_logistic(value)
    if value >= zero(value)
        return inv(one(value) + exp(-value))
    end
    exponential = exp(value)
    return exponential / (one(value) + exponential)
end

@inline function _phs_logit(fraction)
    return log(fraction) - log1p(-fraction)
end

function _phs_encode_coupled_state(
    initial,
    canopy_height,
    gamma_star,
    ca,
    gs_upper,
    potential_scale,
)
    input_type = eltype(initial)
    T = input_type <: AbstractFloat ? promote_type(input_type, Float64) : input_type
    z = zero(T)
    o = one(T)
    transform_floor = sqrt(eps(T))

    height = T(canopy_height)
    gamma = T(gamma_star)
    ambient = T(ca)
    conductance_upper = T(gs_upper)
    scale = max(abs(T(potential_scale)), o)

    if !all(isfinite, initial) ||
            !all(isfinite, (height, gamma, ambient, conductance_upper, scale)) ||
            height < z || ambient <= gamma || conductance_upper <= z
        return nothing
    end

    # Repair only the initial guess. The residual function itself is never
    # projected or clamped, so NonlinearSolve sees a smooth state mapping.
    root = min(T(initial[3]), z)
    stem = min(T(initial[2]), root - height)
    leaf = min(T(initial[1]), stem)
    ci = clamp(T(initial[4]), gamma, ambient)
    gs = clamp(T(initial[5]), z, conductance_upper)

    root_magnitude = max(-root / scale, transform_floor)
    root_to_stem_drop = max((root - height - stem) / scale, transform_floor)
    stem_to_leaf_drop = max((stem - leaf) / scale, transform_floor)

    ci_fraction = clamp(
        (ci - gamma) / (ambient - gamma),
        transform_floor,
        o - transform_floor,
    )
    gs_fraction = clamp(
        gs / conductance_upper,
        transform_floor,
        o - transform_floor,
    )

    coordinates = SVector{5,T}(
        _phs_inverse_softplus(root_magnitude),
        _phs_inverse_softplus(root_to_stem_drop),
        _phs_inverse_softplus(stem_to_leaf_drop),
        _phs_logit(ci_fraction),
        _phs_logit(gs_fraction),
    )
    transform = (
        canopy_height=height,
        gamma_star=gamma,
        ca=ambient,
        gs_upper=conductance_upper,
        potential_scale=scale,
    )
    return coordinates, transform
end

@inline function _phs_decode_coupled_state(coordinates, transform)
    root = -transform.potential_scale * _phs_softplus(coordinates[1])
    root_to_stem_drop =
        transform.potential_scale * _phs_softplus(coordinates[2])
    stem_to_leaf_drop =
        transform.potential_scale * _phs_softplus(coordinates[3])

    stem = root - transform.canopy_height - root_to_stem_drop
    leaf = stem - stem_to_leaf_drop
    ci = transform.gamma_star +
        (transform.ca - transform.gamma_star) * _phs_logistic(coordinates[4])
    gs = transform.gs_upper * _phs_logistic(coordinates[5])

    return SVector{5,eltype(coordinates)}(leaf, stem, root, ci, gs)
end

@inline function _phs_solver_stat(solution, field::Symbol)
    return hasproperty(solution.stats, field) ? Int(getproperty(solution.stats, field)) : 0
end

function _phs_candidate_from_solution(
    nonlinear_solution,
    residual,
    transform,
    tolerance,
    method::Symbol,
)
    coordinates = nonlinear_solution.u
    finite_coordinates = all(isfinite, coordinates)
    solution = finite_coordinates ?
        _phs_decode_coupled_state(coordinates, transform) :
        _phs_decode_coupled_state(zero(coordinates), transform)
    residual_values = finite_coordinates ? residual(solution) : nothing
    finite_residual = !isnothing(residual_values) && all(isfinite, residual_values)
    residual_norm = finite_residual ?
        _phs_norm5(residual_values) : floatmax(eltype(solution))
    objective = finite_residual ?
        _phs_merit(residual_values) : floatmax(eltype(solution))
    successful_retcode = NLS.SciMLBase.successful_retcode(
        nonlinear_solution.retcode,
    )
    converged = successful_retcode && residual_norm <= tolerance

    status = if converged
        method === :trust_region ? :trust_region_converged : :lm_converged
    elseif method === :trust_region
        :trust_region_failed
    else
        :lm_failed
    end

    return (
        solution=solution,
        coordinates=coordinates,
        residual=residual_values,
        residual_norm=residual_norm,
        objective=objective,
        converged=converged,
        status=status,
        retcode=nonlinear_solution.retcode,
        iterations=_phs_solver_stat(nonlinear_solution, :nsteps),
        function_evaluations=_phs_solver_stat(nonlinear_solution, :nf),
        jacobian_evaluations=_phs_solver_stat(nonlinear_solution, :njacs),
        linear_solves=_phs_solver_stat(nonlinear_solution, :nsolve),
        used_lm=method === :levenberg_marquardt,
    )
end

function _phs_initial_candidate(initial, residual, ::Type{T}) where {T}
    solution = SVector{5,T}(initial)
    residual_values = residual(solution)
    finite_residual = all(isfinite, residual_values)
    residual_norm = finite_residual ? _phs_norm5(residual_values) : floatmax(T)
    objective = finite_residual ? _phs_merit(residual_values) : floatmax(T)
    return (
        solution=solution,
        coordinates=nothing,
        residual=residual_values,
        residual_norm=residual_norm,
        objective=objective,
        converged=false,
        status=:invalid_solver_setup,
        retcode=nothing,
        iterations=0,
        function_evaluations=1,
        jacobian_evaluations=0,
        linear_solves=0,
        used_lm=false,
    )
end

@inline function _phs_prefer_candidate(candidate, current)
    if candidate.converged != current.converged
        return candidate.converged
    end
    return candidate.residual_norm < current.residual_norm ||
        (candidate.residual_norm == current.residual_norm &&
         isnothing(current.retcode) && !isnothing(candidate.retcode))
end

"""
    solve_coupled_phs_equilibrium(initial, residual, potential_scale; kwargs...)

Solve the five-equation PHS equilibrium with NonlinearSolve.jl. A smooth
internal parameterization enforces
`psi_leaf < psi_stem < psi_root - canopy_height`, `psi_root < 0`,
`gamma_star < ci < ca`, and `0 < gs < gs_upper` without applying projection
inside the residual function.

The primary algorithm is `TrustRegion`. If it does not satisfy the strict
maximum-residual criterion, `LevenbergMarquardt` is run as a deterministic
fallback. A SciML success return code alone is never treated as PHS
convergence: every returned physical state is checked again with `residual`.
"""
function solve_coupled_phs_equilibrium(
    initial,
    residual,
    potential_scale;
    canopy_height,
    gamma_star,
    ca,
    gs_upper,
    residual_tolerance=1.0e-6,
    maximum_iterations::Int=_PHS_COUPLED_MAX_ITERATIONS,
    use_levenberg_marquardt_fallback::Bool=true,
)
    length(initial) == 5 ||
        throw(DimensionMismatch("coupled PHS requires five state variables"))
    maximum_iterations > 0 ||
        throw(ArgumentError("maximum_iterations must be positive"))

    input_type = eltype(initial)
    T = input_type <: AbstractFloat ? promote_type(input_type, Float64) : input_type
    z = zero(T)
    tolerance = T(residual_tolerance)
    encoded = _phs_encode_coupled_state(
        initial,
        canopy_height,
        gamma_star,
        ca,
        gs_upper,
        potential_scale,
    )

    if isnothing(encoded) || !(isfinite(tolerance) && tolerance > z)
        candidate = _phs_initial_candidate(initial, residual, T)
        return _phs_coupled_result(
            candidate.solution,
            :invalid_solver_setup,
            false,
            0,
            candidate.residual_norm,
            z,
            z;
            objective=candidate.objective,
            function_evaluations=candidate.function_evaluations,
        )
    end

    initial_coordinates, transform = encoded
    solver_residual = (coordinates, _) -> begin
        state = _phs_decode_coupled_state(coordinates, transform)
        values = residual(state)
        return SVector{5,eltype(coordinates)}(values)
    end
    differentiation = NLS.AutoFiniteDiff()

    feasible_initial = _phs_decode_coupled_state(initial_coordinates, transform)
    initial_candidate = _phs_initial_candidate(feasible_initial, residual, T)
    best = initial_candidate
    primary_solution = nothing
    total_iterations = 0
    total_function_evaluations = initial_candidate.function_evaluations
    total_jacobian_evaluations = 0
    total_linear_solves = 0

    try
        problem = NLS.NonlinearProblem(
            solver_residual,
            initial_coordinates,
            nothing,
        )
        primary_solution = NLS.solve(
            problem,
            NLS.TrustRegion(; autodiff=differentiation);
            abstol=tolerance,
            reltol=z,
            maxiters=maximum_iterations,
        )
        primary_candidate = _phs_candidate_from_solution(
            primary_solution,
            residual,
            transform,
            tolerance,
            :trust_region,
        )
        total_iterations += primary_candidate.iterations
        total_function_evaluations += primary_candidate.function_evaluations
        total_jacobian_evaluations += primary_candidate.jacobian_evaluations
        total_linear_solves += primary_candidate.linear_solves
        _phs_prefer_candidate(primary_candidate, best) &&
            (best = primary_candidate)
    catch
        # CMA-ES must receive a finite failed result rather than lose the whole
        # parameter evaluation when an inner numerical solve raises an error.
    end

    fallback_steps = 0

    if !best.converged && use_levenberg_marquardt_fallback
        fallback_steps = 1
        fallback_initial = if !isnothing(primary_solution) &&
                all(isfinite, primary_solution.u)
            primary_solution.u
        else
            initial_coordinates
        end

        try
            least_squares_problem = NLS.NonlinearLeastSquaresProblem(
                solver_residual,
                fallback_initial,
                nothing,
            )
            fallback_solution = NLS.solve(
                least_squares_problem,
                NLS.LevenbergMarquardt(; autodiff=differentiation);
                abstol=tolerance,
                reltol=z,
                maxiters=maximum_iterations,
            )
            fallback_candidate = _phs_candidate_from_solution(
                fallback_solution,
                residual,
                transform,
                tolerance,
                :levenberg_marquardt,
            )
            total_iterations += fallback_candidate.iterations
            total_function_evaluations += fallback_candidate.function_evaluations
            total_jacobian_evaluations += fallback_candidate.jacobian_evaluations
            total_linear_solves += fallback_candidate.linear_solves
            _phs_prefer_candidate(fallback_candidate, best) &&
                (best = fallback_candidate)
        catch
            # The strict residual check below keeps this a failed solve.
        end
    end

    # Re-evaluate after candidate selection so convergence always refers to the
    # exact physical state returned to plantHydraulics_PHS.jl.
    final_residual = residual(best.solution)
    final_is_finite = all(isfinite, final_residual)
    final_norm = final_is_finite ? _phs_norm5(final_residual) : floatmax(T)
    final_objective = final_is_finite ? _phs_merit(final_residual) : floatmax(T)
    final_converged = best.converged && final_norm <= tolerance
    final_status = final_converged ? best.status :
        (best.used_lm ? :lm_failed : :trust_region_failed)

    return _phs_coupled_result(
        best.solution,
        final_status,
        final_converged,
        total_iterations,
        final_norm,
        z,
        z;
        objective=final_objective,
        function_evaluations=total_function_evaluations + 1,
        fallback_steps=fallback_steps,
        restarts=fallback_steps,
        used_lm=best.used_lm,
        retcode=best.retcode,
        jacobian_evaluations=total_jacobian_evaluations,
        linear_solves=total_linear_solves,
    )
end

"""Return a finite, graded CMA-ES penalty for an inner-solver result."""
function plant_hydraulic_solver_penalty(
    result;
    residual_weight=1.0,
    failure_weight=1.0,
)
    residual = isfinite(result.residual_norm) ?
        max(result.residual_norm, zero(result.residual_norm)) :
        floatmax(typeof(result.residual_norm))
    return residual_weight * log1p(residual) +
        (result.converged ? zero(failure_weight) : failure_weight)
end
