"""
Extension methods for `optimizer` using the GCMAES solver (`GCMAESOpt`) from OptimizationGCMAES.
"""

import Sindbad.ParameterOptimization: optimizer
using Sindbad: OptimizationGCMAESDef, OptimizationGCMAESFD

const GCMAES = OptimizationGCMAES.GCMAES

# ------------------------------------------------------------------------------------------------
# Box constraints
#
# GCMAES only respects lb/ub when it is called with `trans = true` (BoxLinQuadTransform); its
# default is `trans = false`, and OptimizationGCMAES drops every solver kwarg except
# maxiters/maxtime, so `trans` cannot be passed through `solve`. Without it, lb/ub are stored but
# never used and the CMA-ES samples (and the result) can leave the bounds.
#
# We therefore apply GCMAES' own BoxLinQuadTransform here: CMA-ES searches an unbounded space z,
# the model is always evaluated at x = transform(z) ∈ [lb, ub] (linear inside, quadratic near
# the bounds, reflected/periodic outside), and the result is mapped back with the same transform.
# ------------------------------------------------------------------------------------------------
function boxTransformedProblem(cost_function, default_values, lower_bounds, upper_bounds)
    T = eltype(default_values)
    tr = GCMAES.BoxLinQuadTransform(collect(T, lower_bounds), collect(T, upper_bounds))
    cost_z = z -> cost_function(GCMAES.transform(tr, z))
    z0 = GCMAES.inverse(tr, collect(T, default_values))
    # GCMAES does not use lb/ub without `trans`; they are only passed because GCMAESOpt requires bounds
    lb_z = fill(typemin(T), length(z0))
    ub_z = fill(typemax(T), length(z0))
    return tr, cost_z, z0, lb_z, ub_z
end

# CMA-ES without gradient information (no AD backend passed to OptimizationFunction). >> just CMAES.
function optimizer(cost_function, default_values, lower_bounds, upper_bounds, algo_options, ::OptimizationGCMAESDef)
    tr, cost_z, z0, lb_z, ub_z = boxTransformedProblem(cost_function, default_values, lower_bounds, upper_bounds)
    optim_cost_f = OptimizationFunction((z, tmp=nothing) -> cost_z(z))
    optim_prob = OptimizationProblem(optim_cost_f, z0; lb=lb_z, ub=ub_z)
    optim_sol = solve(optim_prob, GCMAESOpt(); algo_options...)
    return GCMAES.transform(tr, optim_sol.u)
end

# Gradient-assisted CMA-ES, gradient via central finite differences (FiniteDiff, 2N cost evaluations).
# Optional algo options (both removed before calling solve):
#   `ls_alphas`  (default [0.01, 0.03, 0.1, 0.3]): line-search step lengths along -∇f/‖∇f‖ in the
#                (scaled, box-transformed) optimisation space; see the GCMAES.linesearch override below.
#   `fd_relstep` (default cbrt(eps(Float32)) ≈ 4.9e-3): relative (and absolute) central-difference step.
function optimizer(cost_function, default_values, lower_bounds, upper_bounds, algo_options, ::OptimizationGCMAESFD)
    tr, cost_z, z0, lb_z, ub_z = boxTransformedProblem(cost_function, default_values, lower_bounds, upper_bounds)

    # FD step: the TEM runs in Float32, so the FiniteDiff default (cbrt(eps(Float64)) ≈ 6e-6) gives
    # loss differences at the Float32 round-off level (gradient = noise). Default here: cbrt(eps(Float32)).
    fd_relstep = hasproperty(algo_options, :fd_relstep) ? Float64(algo_options.fd_relstep) : Float64(cbrt(eps(Float32)))
    algo_options = Base.structdiff(algo_options, NamedTuple{(:fd_relstep,)})
    ∇loss!_wrapper = (G, z, p=nothing) -> FiniteDiff.finite_difference_gradient!(G, cost_z, z, Val(:central); relstep=fd_relstep, absstep=fd_relstep)
    optim_cost_fd = OptimizationFunction(
        (z, tmp=nothing) -> cost_z(z),
        SciMLBase.NoAD();
        grad = ∇loss!_wrapper
    )
    optim_prob = OptimizationProblem(optim_cost_fd, z0; lb=lb_z, ub=ub_z)

    # configure the gradient line search; `ls_alphas` is our own option and must not be forwarded
    if hasproperty(algo_options, :ls_alphas)
        LS_ALPHAS[] = Float64.(collect(algo_options.ls_alphas))
        algo_options = Base.structdiff(algo_options, NamedTuple{(:ls_alphas,)})
    else
        LS_ALPHAS[] = copy(DEFAULT_LS_ALPHAS)
    end

    optim_sol = solve(optim_prob, GCMAESOpt(); algo_options...)
    return GCMAES.transform(tr, optim_sol.u)
end

function ∇loss!(G, x, p, cost_function)
    FiniteDiff.finite_difference_gradient!(G, cost_function, x)
end

# ------------------------------------------------------------------------------------------------
# Line-search override for GCMAES
#
# GCMAES.linesearch uses step lengths αs = [0; 2.0 .^ (2 - nworkers():0)]. Without Distributed
# workers (nworkers() == 1) this is αs = [0.0], i.e. the mean never moves along -∇f and the FD
# gradient (2N cost evaluations per generation) is wasted. In addition, α ∈ {.., 0.5, 1} would be
# far too large in Sindbad's scaled parameter space (scale_default: x0 = 1 for every parameter).
#
# This method is strictly more specific than GCMAES' `linesearch(f, x0::Array{T}, Δ) where T`,
# so it replaces it for vector parameters without overwriting the original method.
#   - steps z = z0 + α·Δ/‖Δ‖ for α in [0; LS_ALPHAS[]] (bounds are handled by the box transform)
#   - evaluated serially (each cost evaluation is already threaded over sites)
#   - non-finite costs are treated as +Inf (the original `findmin` would pick a NaN)
# With a zero gradient (OptimizationGCMAESDef passes g = zero) it returns immediately, as before.
# ------------------------------------------------------------------------------------------------
const DEFAULT_LS_ALPHAS = [0.01, 0.03, 0.1, 0.3]
const LS_ALPHAS = Ref{Vector{Float64}}(copy(DEFAULT_LS_ALPHAS))

function GCMAES.linesearch(f, x0::Vector{T}, Δ::AbstractVector) where {T<:AbstractFloat}
    nrm = sqrt(sum(abs2, Δ))
    (iszero(nrm) || !isfinite(nrm)) && return x0, typemax(T), zero(T)
    d = Δ ./ nrm
    xs = [x0 .+ α .* d for α in [zero(T); T.(LS_ALPHAS[])]]
    fs = map(xs) do x
        c = f(x)
        isfinite(c) ? c : typemax(c)
    end
    fx, i = findmin(fs)
    return xs[i], fx, fs[1] - fx
end
