# Contributing to SINDBAD

Thank you for your interest in contributing to SINDBAD! This guide will help you get started with development.

## Development Setup

### Prerequisites

- Julia 1.10 or later
- Git (for cloning the repository)

### Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/LandEcosystems/Sindbad.jl.git
   cd Sindbad.jl
   ```

2. Start Julia in the repository root:
   ```bash
   julia
   ```

3. Navigate to the sandbox directory:
   ```julia
   cd("sandbox")
   ```

4. Create a new sandbox environment:
   ```julia
   run(`mkdir -p my_env`)
   cd("my_env")
   ```

5. Activate the environment and set up development dependencies:
   ```julia
   using Pkg
   Pkg.activate(".")
   ```

### Setting Up Development Dependencies

If you are **using** SINDBAD (not developing), prefer installing from the Julia registry:

```julia
using Pkg
Pkg.add("Sindbad")      # pulls in SindbadTEM automatically
```

If you are **contributing** (working from a local clone of this repository), use `Pkg.develop` so your changes are picked up.

For **SINDBAD Experiments**:
```julia
Pkg.develop(path="../../")  # Sindbad (this repository)

# By default, `SindbadTEM` is resolved from the registry via `Sindbad`'s normal dependencies.
# Only develop `SindbadTEM` locally if you are actively editing it in this monorepo checkout:
# Pkg.develop(path="../../SindbadTEM")

# Add any other local dependencies as needed
Pkg.resolve()
Pkg.instantiate()
```

### Using the `ext/` folder (optional dependencies)

SINDBAD uses Julia’s **package extensions** to keep the core dependency set lean while still supporting optional solver/optimizer backends.

- **What it is**: `ext/` contains extension modules that are loaded automatically *only when* the corresponding optional dependency is present in the active environment.
- **Where it is configured**: see `Project.toml` sections `[weakdeps]` and `[extensions]` (the extension name maps to a file/module in `ext/`).

#### When to use an extension

- **Put code in `ext/`** when it depends on a heavy or optional package (e.g. optimizers, AD backends, nonlinear solvers).
- **Keep code in `src/`** when it is part of the stable, minimal core API and should work without optional packages installed.

#### How to enable an extension locally

Extensions are enabled simply by adding the optional dependency in the same environment:

```julia
using Pkg

# Example: enable an extension by installing its weak dependency
Pkg.add("NLsolve")  # or "Optimization", "CMAEvolutionStrategy", ...
```

Then load/use `Sindbad` normally; the extension will be picked up automatically.

#### Tips for adding a new extension

- **Add a weak dep** in `Project.toml` under `[weakdeps]` and list the mapping under `[extensions]`.
- **Create an extension file** under `ext/` (e.g. `SindbadMyPkgExt.jl`) that defines methods for the relevant hooks/types in `Sindbad`.
- **Avoid hard dependencies**: keep imports of the optional package inside the extension module only.

## Continuous Integration

Every PR automatically runs a required "quick" check on every push (fast, ubuntu-only). Opening
a PR shows the on-demand comment commands (`/check-pr`, `/build-docs`, `/compile-os`,
`/test-simulation`, `/test-models`) available before merging, via the PR template. For the full
detail -- what each CI workflow actually runs, what triggers it automatically, and whether it's
required to merge -- see [`.github/README.md`](.github/README.md).

## Governance

This section describes guiding governance principles for collaborating on SINDBAD.

**External and internal collaborators are equally welcome**. We aim for an open, friendly, and transparent development process, that are also protected and controlled by the main contributor of a new feature or developed.

### Principles

- **Be respectful and constructive**: Assume good intent; keep discussions professional.
- **Be transparent**: Use issues/PRs for decisions and design discussions where possible.
- **Prefer small, reviewable changes**: Smaller PRs are easier to review and merge.
- **Keep science reproducible**: When changing scientific behavior, document the rationale and provide minimal examples/tests when possible.
- **Follow good scientific practice**: See the [Max Planck Society's guidelines for good scientific practice](https://www.mr.mpg.de/14263212/scientificpractice).

### Collaboration guidelines

- **How to collaborate**:
  - Start with an issue (bug report, feature request, proposal), then open a PR.
  - If you are unsure about direction, open a draft PR early to get feedback.
- **Ownership**:
  - Anyone can propose changes; maintainers will help with review and integration.
- **Attribution**:
  - Please keep appropriate citations/attribution in code and documentation.

### Sensitive or unpublished work

SINDBAD is developed in the open. If your work involves **unpublished results, restricted data, or embargoed content**, please coordinate with maintainers *before* pushing such material to the public repository. Changes made in private forks or branches may later be made public by their maintainers.