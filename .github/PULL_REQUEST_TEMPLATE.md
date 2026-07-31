## Summary

<!-- What does this PR change, and why? -->

## Test plan

<!-- How did you verify this works? -->

## Checklist

Every PR runs a fast, ubuntu-only check automatically on every push (required to merge).
The checks below are on-demand -- not required to merge, but expected before merging anything
that could plausibly break on another OS or affect the example setups. Trigger them either way:

- Actions tab -> pick the workflow -> Run workflow -> select this branch, or
- comment on this PR: `/run-full-matrix` (Sindbad.jl + SindbadTEM.jl across all OSes) or
  `/run-simulations` (Test Simulations)

Either way, the result is posted back to this PR automatically as a comment when it finishes.

- [ ] If this PR could behave differently across operating systems: ran `/run-full-matrix` (or
      the Sindbad.jl/SindbadTEM.jl workflows manually) against this branch.
- [ ] If this PR changes `examples/`, `src/`, or anything else that could affect the example
      setups' forward/optimization runs: ran `/run-simulations` (or the Test Simulations
      workflow manually) against this branch.
