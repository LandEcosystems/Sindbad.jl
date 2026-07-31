## Summary

<!-- What does this PR change, and why? -->

## Test plan

<!-- How did you verify this works? -->

## On-demand checks

Every PR runs a fast, ubuntu-only check automatically on every push (required to merge).
For full OS coverage, the example setups, or the docs build, trigger the on-demand checks
before merging -- results post back to this PR as comments automatically:

- `/check-pr` -- Sindbad.jl + SindbadTEM.jl across all OSes, plus the docs build
- `/run-simulations` -- Test Simulations

(or Actions tab -> pick the workflow -> Run workflow -> select this branch)
