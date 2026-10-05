# Designing a SINDBAD Experiment

This guide provides a comprehensive overview of how to design and configure a SINDBAD experiment, based on an example setting. *Note that the settings are different for different experiments*

## Overview

A SINDBAD experiment consists of several configuration files that define:
- Basic experiment settings
- Model structure and parameters
- Forcing data configuration
- ParameterOptimization settings
- Execution rules and flags

## Configuration Files

### 1. Experiment Configuration (`experiment.json`)

The main configuration file that defines the basic experiment settings:

```json
{
  "basics": {
    "config_files": {
      "forcing": "forcing.json",
      "model_structure": "model_structure.json",
      "optimization": "optimization.json"
    },
    "domain": "FLUXNET",
    "name": "WROASTED",
    "time": {
      "date_begin": "1979-01-01",
      "date_end": "2017-12-31",
      "temporal_resolution": "day"
    }
  },
  "exe_rules": {
    "land_output_type": "array",
    "model_array_type": "static_array",
    "model_number_type": "Float32",
    "parallelization": "threads"
  },
  "flags": {
    "calc_cost": true,
    "run_forward": true,
    "run_optimization": true,
    "spinup_TEM": true
  }
}
```

### 2. Model Structure (`model_structure.json`)

Defines the model components and their approaches:

```json
{
  "default_model": {
    "implicit_t_repeat": 1,
    "use_in_spinup": true
  },
  "models": {
    "autoRespiration": {
      "approach": "Thornley2000A"
    },
    "cCycle": {
      "approach": "GSI"
    },
    "gpp": {
      "approach": "coupled"
    }
  },
  "pools": {
    "carbon": {
      "combine": "cEco",
      "components": {
        "cVeg": {
          "Root": [1, 25.0],
          "Wood": [1, 25.0],
          "Leaf": [1, 25.0]
        }
      }
    }
  }
}
```

### 3. Forcing Configuration (`forcing.json`)

Defines the input data sources and their properties:

```json
{
  "data_dimension": {
    "time": "time",
    "permute": ["time", "longitude", "latitude"],
    "space": ["longitude", "latitude"]
  },
  "default_forcing": {
    "data_path": "../data/BE-Vie.1979.2017.daily.nc",
    "source_product": "FLUXNET"
  },
  "variables": {
    "f_ambient_CO2": {
      "bounds": [200, 500],
      "standard_name": "ambient_CO2",
      "sindbad_unit": "ppm",
      "source_unit": "ppm"
    }
  }
}
```

### 4. ParameterOptimization Configuration (`optimization.json`)

Defines optimization parameters and observational constraints:

```json
{
  "algorithm_optimization": "opti_algorithms/CMAEvolutionStrategy_CMAES.json",
  "model_parameters_to_optimize": {
    "autoRespiration,RMN": null,
    "gppAirT,opt_airT": null
  },
  "multi_constraint_method": "metric_sum",
  "observational_constraints": [
    "gpp",
    "nee",
    "reco"
  ],
  "observations": {
    "default_cost": {
      "cost_metric": "NSE_inv",
      "cost_weight": 1.0
    }
  }
}
```

## Key Components

### 1. Experiment Basics

- **Domain**: Geographic or thematic scope
- **Time Period**: Start and end dates
- **Temporal Resolution**: Time step (e.g., day, hour)
- **Name**: Unique experiment identifier

### 2. Model Configuration

- **Model Approaches**: Different implementations for each process
- **Pools**: State variables and their components

### 3. Forcing Data

- **Data Sources**: Input data files and variables
- **Units and Conversions**: Unit specifications and conversions
- **Spatial and Temporal Dimensions**: Data structure and organization

### 4. ParameterOptimization Settings

- **Algorithm**: ParameterOptimization method (e.g., CMA-ES)
- **Parameters**: Parameters to be optimized
- **Constraints**: Observational constraints and metrics
- **Cost Function**: How to evaluate model performance

### 5. Execution Rules

- **Data Types**: Array types and number precision
- **Parallelization**: Threading or other parallel execution
- **Output Format**: Data storage format (e.g., NetCDF, Zarr)

## Best Practices

1. **Experiment Design**
   - Start with a clear research question
   - Choose relevant model components and processes
   - Define appropriate data and methods

2. **Model Configuration**
   - Select appropriate model approaches
   - Define necessary pools and components
   - Set reasonable optimization parameter list and their ranges

3. **Data Management**
   - Ensure data consistency and quality, no gaps in input
   - Use appropriate units and conversions based on what is in the data and what is needed in SINDBAD
   - Handle missing data in constraints appropriately

4. **ParameterOptimization**
   - Choose suitable optimization algorithm
   - Define relevant observational constraints
   - Set appropriate cost metrics and weights

5. **Performance**
   - Use appropriate parallelization
   - Optimize memory usage
   - Consider computational efficiency

## Example Workflow

1. **Setup**
```julia
using Sindbad.Simulation
experiment_json = "path/to/experiment.json"
```

2. **Configuration**
The main configuration are loaded from the json, which can be over-written by `replace_info` at run time.
```julia
replace_info = Dict(
    "experiment.basics.time.date_begin" => "1979-01-01",
    "experiment.basics.time.date_end" => "2017-12-31",
    "experiment.flags.run_optimization" => true
)
```

3. **Run Experiment**
```julia
out_opti = runExperimentOpti(experiment_json; replace_info=replace_info)
```

4. **Analysis**
```julia
# Access results
forcing = out_opti.forcing
observations = out_opti.observation
output = out_opti.output
```

## Experiment Running Functions

SINDBAD provides several functions for running experiments with different configurations and purposes:

:::tip
To list all available experiment methods and their purposes, use:
```julia
using Sindbad.Simulation
using OmniTools: show_methods_of
show_methods_of(RunFlag)
```
This will display a formatted list of all experiment methods and their descriptions.

:::

### 1. `runExperimentOpti`

Runs an optimization experiment followed by a forward run with optimized parameters.

```julia
# Basic optimization run
out_opti = runExperimentOpti(experiment_json)

# Run with custom configuration
replace_info = Dict(
    "experiment.basics.time.date_begin" => "2000-01-01",
    "experiment.basics.time.date_end" => "2017-12-31",
    "experiment.flags.run_optimization" => true
)
out_opti = runExperimentOpti(experiment_json; replace_info=replace_info)

# Run with different logging level
out_opti = runExperimentOpti(experiment_json; log_level=:debug)
```

Returns a NamedTuple containing:
- `forcing`: Forcing data
- `info`: Experiment information
- `loss`: Cost metrics table
- `observation`: Observation data
- `output`: Model outputs (optimized and default)
- `parameters`: Optimized parameter table

### 2. `runExperimentCost`

Calculates cost between model output and observations.

```julia
output_cost = runExperimentCost(experiment_json; replace_info=Dict(), log_level=:info)
```

Returns a NamedTuple containing:
- `forcing`: Forcing data
- `info`: Experiment information
- `loss`: Cost vector
- `observation`: Observation data
- `output`: Model output

### 3. `runExperimentForward`

Runs a forward simulation without optimization.

```julia
output_forward = runExperimentForward(experiment_json; replace_info=Dict(), log_level=:info)
```

Returns a NamedTuple containing:
- `forcing`: Forcing data
- `info`: Experiment information
- `output`: Model output

### 4. `runExperimentForwardParams`

Runs forward simulation with specified parameters.

```julia
output_params = runExperimentForwardParams(params_vector, experiment_json; replace_info=Dict(), log_level=:info)
```

Returns a NamedTuple containing:
- `forcing`: Forcing data
- `info`: Experiment information
- `output`: Model outputs (optimized and default)

### 5. `runExperimentFullOutput`

Runs forward simulation with all output variables saved.

```julia
output_full = runExperimentFullOutput(experiment_json; replace_info=Dict(), log_level=:info)
```

Returns a NamedTuple containing:
- `forcing`: Forcing data
- `info`: Experiment information
- `output`: Complete model outputs

### 6. `runExperimentSensitivity`

Runs sensitivity analysis for a given experiment.

```julia
output_sensitivity = runExperimentSensitivity(experiment_json; replace_info=Dict(), batch=true, log_level=:warn)
```

Returns a NamedTuple containing:
- `forcing`: Forcing data
- `info`: Experiment information
- `sensitivity`: Sensitivity analysis results
- `observation`: Observation data
- `parameters`: Parameter bounds

### Common Parameters

All experiment running functions accept these common parameters:
- `experiment_json::String`: Path to the experiment configuration file
- `replace_info::Dict`: Dictionary of configuration overrides
- `log_level::Symbol`: Logging level (:info, :warn, :debug, etc.)
