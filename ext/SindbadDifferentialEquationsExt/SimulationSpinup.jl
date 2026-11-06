"""
Extension methods for `Sindbad.Simulation.spinup`.

This file is included from the extension module and can use `DifferentialEquations`.
"""

# Bring the target function into scope for adding methods.
import Sindbad.Simulation: spinup
using Sindbad: ODEAutoTsit5Rodas5, ODEDP5, ODETsit5, SSPDynamicSSTsit5, SSPSSRootfind, getSpinupInfo, getDeltaPool, set_namedtuple_subfield

# Example methods (for reference):
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::SSPSSRootfind) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:423
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::ODEDP5) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:378
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::ODEAutoTsit5Rodas5) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:363
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::NlsolveFixedpointTrustregionTWS) @ SindbadNLsolveExt ext/SindbadNLsolveExt/SimulationSpinup.jl:33
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::NlsolveFixedpointTrustregionCEco) @ SindbadNLsolveExt ext/SindbadNLsolveExt/SimulationSpinup.jl:66
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::EtaScaleAH) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:244
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::LoopTEM) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:234
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::EtaScaleA0HCWD) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:335
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::ODETsit5) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:394
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::NlsolveFixedpointTrustregionCEcoTWS) @ SindbadNLsolveExt ext/SindbadNLsolveExt/SimulationSpinup.jl:43
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::SpinupMode) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:215
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::SSPDynamicSSTsit5) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:410
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::EtaScaleA0H) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:302
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::EtaScaleAHCWD) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:275

# ------------------------------------------------------------------
# Add your extension methods below.
# Tip: avoid defining a too-generic method like `spinup(args...)`.
# Instead, add a more specific dispatch (new type, keyword, or argument).
# ------------------------------------------------------------------


"""
    getSpinupInfo(spinup_models, spinup_forcing, loc_forcing_t, land, spinup_pool_name, tem_info, tem_spinup)

helper function to create a NamedTuple with all the variables needed to run the spinup models in getDeltaPool. Used in solvers from DifferentialEquations.jl.


# Arguments:
- `spinup_models`: a tuple of a subset of all models in the given model structure that is selected for spinup
- `spinup_forcing`: a selected/sliced/computed forcing time series for running the spinup sequence for a location
- `loc_forcing_t`: a forcing NT for a single location and a single time step
- `land`: SINDBAD NT input to the spinup of TEM during which subfield(s) of pools are overwritten
- `spinup_pool_name`: name of the land.pool storage component intended for spinup
- `tem_info`: helper NT with necessary objects for model run and type consistencies
"""
function getSpinupInfo(spinup_models, spinup_forcing, loc_forcing_t, land, spinup_pool_name, tem_info, n_timesteps)
    spinup_info = (;)
    spinup_info = set_namedtuple_field(spinup_info, (:pool, spinup_pool_name))
    spinup_info = set_namedtuple_field(spinup_info, (:land, land))
    spinup_info = set_namedtuple_field(spinup_info, (:spinup_forcing, spinup_forcing))
    spinup_info = set_namedtuple_field(spinup_info, (:spinup_models, spinup_models))
    spinup_info = set_namedtuple_field(spinup_info, (:tem_info, tem_info))
    spinup_info = set_namedtuple_field(spinup_info, (:loc_forcing_t, loc_forcing_t))
    spinup_info = set_namedtuple_field(spinup_info, (:n_timesteps, n_timesteps))
    return spinup_info
end


"""
    getDeltaPool(pool_dat::AbstractArray, spinup_info, t)

helper function to run the spinup models and return the delta in a given pool over the simulation. Used in solvers from DifferentialEquations.jl.


# Arguments:
- `pool_dat`: new values of the storage pools
- `spinup_info`: NT with all the necessary information to run the spinup models
"""
function getDeltaPool(pool_dat::AbstractArray, spinup_info, _)
    land = spinup_info.land
    tem_info = spinup_info.tem_info
    spinup_models = spinup_info.spinup_models
    spinup_forcing = spinup_info.spinup_forcing
    loc_forcing_t = spinup_info.loc_forcing_t
    n_timesteps = spinup_info.n_timesteps
    land = set_namedtuple_subfield(land, :pools, (spinup_info.pool, pool_dat))

    land = timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, deepcopy(land), tem_info, n_timesteps)
    tmp = getfield(land.pools, spinup_info.pool)
    Δpool = tmp - pool_dat
    return Δpool
end


function spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::ODEAutoTsit5Rodas5)
    for sel_pool ∈ tem_spinup.differential_eqn.pools
        p_info = getSpinupInfo(spinup_models, spinup_forcing, loc_forcing_t, land, Symbol(sel_pool), tem_info, n_timesteps)
        tspan = (0.0, tem_info.numbers.num_type(tem_spinup.differential_eqn.time_jump))
        init_pool = deepcopy(getfield(p_info.land[:pools], p_info.pool))
        ode_prob = ODEProblem(getDeltaPool, init_pool, tspan, p_info)
        maxIter = tem_spinup.differential_eqn.time_jump
        # maxIter = max(ceil(tem_spinup.differential_eqn.time_jump) / 100, 100)
        ode_sol = solve(ode_prob, AutoVern7(Rodas5()); maxiters=maxIter)
        # ode_sol = solve(ode_prob, Tsit5(), reltol=tem_spinup.differential_eqn.relative_tolerance, abstol=tem_spinup.differential_eqn.absolute_tolerance, maxiters=maxIter)
        land = set_namedtuple_subfield(land, :pools, (p_info.pool, ode_sol.u[end]))
    end
    return land
end

function spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::ODEDP5)
    for sel_pool ∈ tem_spinup.differential_eqn.pools
        p_info = getSpinupInfo(spinup_models, spinup_forcing, loc_forcing_t, land, Symbol(sel_pool), tem_info, n_timesteps)
        tspan = (0.0, tem_info.numbers.num_type(tem_spinup.differential_eqn.time_jump))
        init_pool = deepcopy(getfield(p_info.land[:pools], p_info.pool))
        ode_prob = ODEProblem(getDeltaPool, init_pool, tspan, p_info)
        maxIter = tem_spinup.differential_eqn.time_jump
        maxIter = max(ceil(tem_spinup.differential_eqn.time_jump) / 100, 100)
        ode_sol = solve(ode_prob, DP5(); maxiters=maxIter)
        # ode_sol = solve(ode_prob, Tsit5(), reltol=tem_spinup.differential_eqn.relative_tolerance, abstol=tem_spinup.differential_eqn.absolute_tolerance, maxiters=maxIter)
        land = set_namedtuple_subfield(land, :pools, (p_info.pool, ode_sol.u[end]))
    end
    return land
end


function spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::ODETsit5)
    for sel_pool ∈ tem_spinup.differential_eqn.pools
        p_info = getSpinupInfo(spinup_models, spinup_forcing, loc_forcing_t, land, Symbol(sel_pool), tem_info, n_timesteps)
        tspan = (0.0, tem_info.numbers.num_type(tem_spinup.differential_eqn.time_jump))
        init_pool = deepcopy(getfield(p_info.land[:pools], p_info.pool))
        ode_prob = ODEProblem(getDeltaPool, init_pool, tspan, p_info)
        # maxIter = tem_spinup.differential_eqn.time_jump
        maxIter = max(ceil(tem_spinup.differential_eqn.time_jump) / 100, 100)
        ode_sol = solve(ode_prob, Tsit5(); maxiters=maxIter)
        # ode_sol = solve(ode_prob, Tsit5(), reltol=tem_spinup.differential_eqn.relative_tolerance, abstol=tem_spinup.differential_eqn.absolute_tolerance, maxiters=maxIter)
        land = set_namedtuple_subfield(land, :pools, (p_info.pool, ode_sol.u[end]))
    end
    return land
end


function spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::SSPDynamicSSTsit5)
    for sel_pool ∈ tem_spinup.differential_eqn.pools
        p_info = getSpinupInfo(spinup_models, spinup_forcing, loc_forcing_t, land, Symbol(sel_pool), tem_info, n_timesteps)
        tspan = (0.0, tem_spinup.differential_eqn.time_jump)
        init_pool = deepcopy(getfield(p_info.land[:pools], p_info.pool))
        ssp_prob = SteadyStateProblem(getDeltaPool, init_pool, p_info)
        ssp_sol = solve(ssp_prob, DynamicSS(Tsit5()))
        land = set_namedtuple_subfield(land, :pools, (p_info.pool, ssp_sol.u))
    end
    return land
end


function spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::SSPSSRootfind)
    for sel_pool ∈ tem_spinup.differential_eqn.pools
        p_info = getSpinupInfo(spinup_models, spinup_forcing, loc_forcing_t, land, Symbol(sel_pool), tem_info, n_timesteps)
        tspan = (0.0, tem_spinup.differential_eqn.time_jump)
        init_pool = deepcopy(getfield(p_info.land[:pools], p_info.pool))
        ssp_prob = SteadyStateProblem(getDeltaPool, init_pool, p_info)
        ssp_sol = solve(ssp_prob, SSRootfind())
        land = set_namedtuple_subfield(land, :pools, (p_info.pool, ssp_sol.u))
    end
    return land
end
