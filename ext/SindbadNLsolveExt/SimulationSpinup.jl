"""
Extension methods for `spinup`.

This file is included from the extension module and can use `NLsolve`.
"""

# Bring the target function into scope for adding methods.
using Sindbad.SindbadTEM
import Sindbad.Simulation: spinup
using Sindbad: NlsolveFixedpointTrustregionTWS, NlsolveFixedpointTrustregionCEcoTWS, NlsolveFixedpointTrustregionCEco, @pack_nt, Spinup_TWS, Spinup_cEco_TWS, Spinup_cEco
# Example methods (for reference):
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::EtaScaleA0H) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:329
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::SSPSSRootfind) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:450
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::EtaScaleAH) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:271
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::NlsolveFixedpointTrustregionCEco) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:260
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::NlsolveFixedpointTrustregionCEcoTWS) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:237
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::ODETsit5) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:421
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::LoopTEM) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:217
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::NlsolveFixedpointTrustregionTWS) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:227
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::SSPDynamicSSTsit5) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:437
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::ODEAutoTsit5Rodas5) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:390
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::ODEDP5) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:405
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::EtaScaleAHCWD) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:302
# - spinup(::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::EtaScaleA0HCWD) @ Sindbad.Simulation src/Simulation/spinupTEM.jl:362

# ------------------------------------------------------------------
# Add your extension methods below.
# Tip: avoid defining a too-generic method like `spinup(args...)`.
# Instead, add a more specific dispatch (new type, keyword, or argument).
# ------------------------------------------------------------------

function spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::NlsolveFixedpointTrustregionTWS)
    TWS_spin = Spinup_TWS(spinup_models, spinup_forcing, tem_info, land, loc_forcing_t, n_timesteps)
    r = fixedpoint(TWS_spin, Vector(deepcopy(land.pools.TWS)); method=:trust_region)
    TWS = r.zero
    TWS = oftype(land.pools.TWS, TWS)
    @pack_nt TWS ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, tem_info.model_helpers, land.models.w_model)
    return land
end

function spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::NlsolveFixedpointTrustregionCEcoTWS)
    cEco_TWS_spin = Spinup_cEco_TWS(spinup_models, spinup_forcing, tem_info, deepcopy(land), loc_forcing_t, n_timesteps, Vector(deepcopy(land.pools.TWS)))
    p_init = log.(Vector(deepcopy(land.pools.cEco)))
    # r = fixedpoint(cEco_TWS_spin, p_init; method=:trust_region)
    # cEco = exp.(r.zero)
    cEco = land.pools.cEco
    try
        r = fixedpoint(cEco_TWS_spin, p_init; method=:trust_region)
        cEco = exp.(r.zero)
    catch
        cEco = land.pools.cEco
    end
    cEco = oftype(land.pools.cEco, cEco)
    @pack_nt cEco ⇒ land.pools
    TWS_prev = cEco_TWS_spin.TWS
    TWS = oftype(land.pools.TWS, TWS_prev)
    @pack_nt TWS ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, tem_info.model_helpers, land.models.c_model)
    land = SindbadTEM.adjustPackPoolComponents(land, tem_info.model_helpers, land.models.w_model)
    return land
end


function spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::NlsolveFixedpointTrustregionCEco)
    cEco_spin = Spinup_cEco(spinup_models, spinup_forcing, tem_info, deepcopy(land), loc_forcing_t, n_timesteps)
    p_init = log.(Vector(deepcopy(land.pools.cEco)))
    r = fixedpoint(cEco_spin, p_init; method=:trust_region)
    cEco = exp.(r.zero)
    cEco = oftype(land.pools.cEco, cEco)
    @pack_nt cEco ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, tem_info.model_helpers, land.models.c_model)
    return land
end
