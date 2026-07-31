## Summary

<!-- What does this PR change, and why? -->

## Test plan

<!-- How did you verify this works? -->

## Checklist

Every PR runs a fast, ubuntu-only check automatically on every push (required to merge).
The checks below are on-demand -- not required to merge, but expected before merging anything
that could plausibly break on another OS, affect the example setups, or break the docs build.
Trigger them either way:

- Actions tab -> pick the workflow -> Run workflow -> select this branch, or
- comment on this PR: `/check-pr` (Sindbad.jl + SindbadTEM.jl across all OSes, plus the docs
  build) or `/run-simulations` (Test Simulations)

`/check-pr` posts a PR comment for the Sindbad.jl/SindbadTEM.jl matrix result, and reports the
docs build via its own `documenter/deploy` status check (same as it always has). `/run-simulations`
posts its result back to this PR automatically as a comment.

- [ ] If this PR could behave differently across operating systems, or changes `docs/` or
      anything documented via docstrings: ran `/check-pr` (or the Sindbad.jl/SindbadTEM.jl/
      Documenter workflows manually) against this branch.
- [ ] If this PR changes `examples/`, `src/`, or anything else that could affect the example
      setups' forward/optimization runs: ran `/run-simulations` (or the Test Simulations
      workflow manually) against this branch.
