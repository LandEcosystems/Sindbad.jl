# SINDBAD Spinup
This documentation introduces SINDBAD spinup and provides a framework for adding new spinup methods while maintaining consistency with SINDBAD's architecture.

Spinup is carried out in every experiment to take the model state to an equilibrium. The equilibrium is dependent on data, model and parameters, and should therefore, a Spinup is always required.

## Configuration

Spinup is configured in the experiment settings file through two main sections:

1. **Flags Section**:
```json
"flags": {
    "spinup_TEM": true,
    "store_spinup": false
}
```
- `spinup_TEM`: Activates the spinup process
- `store_spinup`: Controls whether to store spinup results from each sequence

2. **Spinup Sequence**:
```json
"spinup_sequence": [
    {
        "forcing": "all_years",
        "n_repeat": 1,
        "spinup_mode": "all_forward_models"
    }
]
```
- `spinup_sequence`: Array of spinup steps executed sequentially, or a sequence method with its options
  - `forcing`: Forcing variant to use
  - `n_repeat`: Number of sequence repetitions
  - `spinup_mode`: The spinup method to use

## Available Spinup Methods

Spinup methods are stored in spinup functions within SindbadTEM. The different methods are dispatched on types generated. 

```julia
using Sindbad.Simulation
?Sindbad.Simulation.spinup
```

::: tip
To list all available spinup methods and their purposes, use:
```julia
using Sindbad.Simulation
using OmniTools: show_methods_of
show_methods_of(SpinupMode)
```
This will display a formatted list of all spinup methods and their descriptions.

:::

Current methods include:
- `AllForwardModels`: Use all forward models for spinup
- `EtaScaleA0H`: Scale carbon pools using diagnostic scalars for ηH and c_remain
- `EtaScaleAH`: Scale carbon pools using diagnostic scalars for ηH and ηA
- `NlsolveFixedpointTrustregionCEco`: Use a fixed-point nonlinear solver with trust region for carbon pools (cEco)
- `NlsolveFixedpointTrustregionCEcoTWS`: Use a fixed-point nonlinear solver with trust region for both cEco and TWS
- `NlsolveFixedpointTrustregionTWS`: Use a fixed-point nonlinear solver with trust region for Total Water Storage (TWS)
- `ODEAutoTsit5Rodas5`: Use the AutoVern7(Rodas5) method from DifferentialEquations.jl for solving ODEs
- `ODEDP5`: Use the DP5 method from DifferentialEquations.jl for solving ODEs
- `ODETsit5`: Use the Tsit5 method from DifferentialEquations.jl for solving ODEs
- `SelSpinupModels`: Run only the models selected for spinup in the model structure
- `SSPDynamicSSTsit5`: Use the SteadyState solver with DynamicSS and Tsit5 methods
- `SSPSSRootfind`: Use the SteadyState solver with SSRootfind method

## Adding New Spinup Methods

SINDBAD uses a type-based dispatch system for spinup methods. To add a new spinup method, you need to:

1. Define a new type in `src/Types/SpinupTypes.jl`
2. Implement the spinup function in `spinupTEM.jl`
3. Update the spinup sequence handling if needed

### 1. Define the New Spinup Method Type

In `src/Types/SpinupTypes.jl`, add a new struct and its purpose function:

```julia
import OmniTools: purpose

# Define the new spinup type
struct YourNewSpinupMode <: SpinupMode end

# Define its purpose
purpose(::Type{YourNewSpinupMode}) = "Description of what YourNewSpinupMode does"
```

::: info
When naming new spinup types that use external packages, follow the convention `PackageNameMethodName`. For example:
- `ODEAutoTsit5Rodas5` for the AutoVern7(Rodas5) method from DifferentialEquations.jl
- `NlsolveFixedpointTrustregionCEco` for the fixed-point solver from NLsolve.jl
- `SSPDynamicSSTsit5` for the SteadyState solver with DynamicSS and Tsit5 methods

This convention helps identify both the package and the specific method being used.

:::

The purpose function should:
- Be concise but informative
- Focus on what the spinup method does and which pools it affects
- Include any special conditions or requirements
- Use consistent formatting with other spinup methods

### 2. Implement the Spinup Function

In `spinupTEM.jl`, implement the spinup function:
```julia
function spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::YourNewSpinupMode)
    # Your implementation here
end
```

The function should:
1. Update the land state using provided models and forcing
2. Return the updated land state

Example implementation:
```julia
function spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::YourNewSpinupMode)
    # Create custom spinup structure if needed
    spinup_struct = YourSpinupStruct(spinup_models, spinup_forcing, tem_info, land, loc_forcing_t, n_timesteps)
    
    # Implement spinup logic
    # This could involve:
    # - Running time loops
    # - Using solvers
    # - Applying scaling factors
    
    # Update land state
    land = updateLandState(land, spinup_results)
    
    return land
end
```

### 3. Update Spinup Sequence Handling (if needed)

If your method requires special sequence handling:
```julia
function spinupSequence(spinup_models, sel_forcing, loc_forcing_t, land, tem_info, n_timesteps, log_index, n_repeat, ::YourNewSpinupMode)
    land = spinupSequenceLoop(spinup_models, sel_forcing, loc_forcing_t, land, tem_info, n_timesteps, log_index, n_repeat, YourNewSpinupMode())
    return land
end
```

## Important Considerations

1. **State Variables**: Handle all relevant state variables (carbon pools, water storage, etc.)

2. **Performance**: Implement efficient memory management and consider parallelization

3. **Convergence**: Include appropriate convergence criteria and error handling

4. **Documentation**: Add comprehensive docstrings explaining:
   - Mode/Method purpose
   - Required parameters
   - Return values
   - Special considerations

## Testing

After implementation:
1. Test with small experiments
2. Verify spinup results match expectations

