# SINDBAD

[![][docs-stable-img]][docs-stable-url][![][docs-dev-img]][docs-dev-url][![][ci-img]][ci-url] [![][codecov-img]][codecov-url][![Julia][julia-img]][julia-url][![License: EUPLv1.2](https://img.shields.io/badge/License-EUPLv1.2-seagreen)](https://github.com/LandEcosystems/Sindbad/blob/main/LICENSE)

<img src="docs/src/assets/sindbad_logo.png" align="right" style="padding-left:10px;" width="150"/>

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://landecosystems.github.io/Sindbad.jl/dev/

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://landecosystems.github.io/Sindbad.jl/stable/

[codecov-img]: https://codecov.io/gh/LandEcosystems/Sindbad.jl/branch/main/graph/badge.svg
[codecov-url]: https://codecov.io/gh/LandEcosystems/Sindbad.jl

[ci-img]: https://github.com/LandEcosystems/Sindbad.jl/workflows/Sindbad.jl/badge.svg
[ci-url]: https://github.com/LandEcosystems/Sindbad.jl/actions?query=workflow%3A%22Sindbad.jl%22

[julia-img]: https://img.shields.io/badge/julia-v1.10+-blue.svg
[julia-url]: https://julialang.org/

Welcome to the repository for **S**trategies to **IN**tegrate **D**ata and **B**iogeochemic**A**l mo**D**els (SINDBAD).

## Overview

SINDBAD is a model data integration framework that encompasses the biogeochemical cycles of water and carbon, allowing for extensive and flexible integration of parsimonious models with a diverse set of observational data streams.

The framework provides a unified system for:
- **Model Structure**: Adaptable ecosystem process representations
- **Input Data**: Flexible data ingestion and processing
- **Observation Data**: Versatile observational constraint integration
- **Integration Methods**: Customizable optimization and assimilation approaches

## Repository Structure

This repository contains the `Sindbad` package sources. The `Sindbad` package depends on several other registered packages (some maintained in separate repositories), which are installed automatically by Julia’s package manager.

- **`src/`**: `Sindbad` user-facing modules:
  - `DataLoaders/`: Data loading and preprocessing
  - `Setup/`: Experiment configuration and setup
  - `Simulation/`: Terrestrial ecosystem model execution
  - `ParameterOptimization/`: Parameter calibration and optimization
  - `MachineLearning/`: ML-assisted surrogates and emulators
  - `Visualization/`: Plotting and visualization tools
  - `Experiment/`: High-level experiment orchestration
  - `Types/`: Type definitions for SINDBAD structures
- **`ext/`**: Extension packages for optional dependencies
- **`examples/`**: Example experiments and configurations
- **`docs/`**: Documentation source files

Internal packages (SINDBAD core):
- **`SindbadTEM`**: Core terrestrial ecosystem models, types, and utilities

Related packages (SINDBAD ecosystem):
- **`ErrorMetrics.jl`**: Model–observation metrics (maintained in a separate repository)
- **`TimeSamplers.jl`**: Time aggregation / sampling utilities (maintained in a separate repository)
- **`OmniTools.jl`**: Shared utility toolkit (maintained in a separate repository)

## Installation

### From a Julia package registry (recommended)

```julia
using Pkg
Pkg.add("Sindbad")
```


### From source (development / monorepo checkout)

If you are working from a checkout of this repository:

```julia
using Pkg
Pkg.activate("path/to/SINDBAD")
Pkg.instantiate()
using Sindbad
```

If you are using SSH-based package sources for SINDBAD ecosystem packages, you may need to tell Julia to use the system `git` client:

```bash
export JULIA_PKG_USE_CLI_GIT=true
```

If you want to develop `Sindbad` from a separate environment, you can also use:

```julia
using Pkg
Pkg.develop(path="path/to/SINDBAD")
```

### Optional dependencies (extensions)

Some functionality is enabled via Julia package extensions (see `Project.toml` `[weakdeps]` + `[extensions]` and `ext/`):

- **`NLsolve`**: enables parts of the spinup workflow (`SindbadNLsolveExt`)
- **`Optimization`**: enables SciML Optimization-based optimizers (`SindbadOptimizationExt`)
- **`CMAEvolutionStrategy`**: enables CMA-ES optimizer bridge (`SindbadCMAEvolutionStrategyExt`)

To enable an extension, add the corresponding package **in the same environment** where you use `Sindbad`:

```julia
using Pkg
Pkg.add("NLsolve")  # or "Optimization", "CMAEvolutionStrategy"
```

For development setup and usage instructions, see [CONTRIBUTING.md](./CONTRIBUTING.md).

## Quick Start

```julia
using Sindbad

# Run a forward simulation for an experiment configuration
out = Sindbad.Experiment.runExperimentForward("experiment_config.json")

# `out` contains `out.info`, `out.forcing`, and `out.output`
```

## Documentation

Comprehensive documentation is available at:
- **Stable**: [landecosystems.github.io/Sindbad.jl/stable](https://landecosystems.github.io/Sindbad.jl/stable/)
- **Development**: [landecosystems.github.io/Sindbad.jl/dev](https://landecosystems.github.io/Sindbad.jl/dev/)

## SINDBAD Contributors

SINDBAD is developed at the Department of Biogeochemical Integration of the Max Planck Institute for Biogeochemistry in Jena, Germany with active contributions from [Sujan Koirala](https://www.bgc-jena.mpg.de/person/skoirala/2206), [Xu Shan](https://www.bgc-jena.mpg.de/person/138641/2206), [Jialiang Zhou](https://www.bgc-jena.mpg.de/person/137086/2206), [Lazaro Alonso](https://www.bgc-jena.mpg.de/person/lalonso/2206), [Fabian Gans](https://www.bgc-jena.mpg.de/person/fgans/4777761), [Felix Cremer](https://www.bgc-jena.mpg.de/person/fcremer/2206), [Nuno Carvalhais](https://www.bgc-jena.mpg.de/person/ncarval/2206).

For a full list of current and previous contributors, see [sindbad-mdi.org team page](http://sindbad-mdi.org/pages/about/team.html)

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines on:
- Development setup
- Code style and conventions
- Submitting pull requests
- Reporting issues

## Copyright and License

**SINDBAD: Strategies to Integrate Data and Biogeochemical Models**

**Copyright © 2025**  
Max-Planck-Gesellschaft zur Förderung der Wissenschaften

For copyright details, see the [NOTICE](./NOTICE) file.

---

### License

SINDBAD is free and open-source software, licensed under the [European Union Public License v1.2 (EUPL)](https://eupl.eu/1.2/en).

---

### Your Rights

You are free to:

- Copy, modify, and redistribute the code  
- Use the software as a package in your own projects, regardless of their license or copyright status  
- Apply the software in both commercial and non-commercial contexts  

---

### Your Responsibilities

If you modify the code — excluding changes made solely for interoperability — you **must redistribute the modified version under the EUPL v1.2 or a compatible license**. This ensures the long-term sustainability of the project and supports an open, inclusive, and collaborative community.

---

### Disclaimer

This software is provided in the hope that it will be useful, but **without any warranty** — including, without limitation, the implied warranties of merchantability or fitness for a particular purpose.
