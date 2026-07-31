## Summary

<!-- What does this PR change, and why? -->

## Test plan

<!-- How did you verify this works? -->

## On-demand checks

Every PR runs a fast, ubuntu-only check automatically on every push (required to merge).
When everything is ready, run `/check-pr` to run the full tests required before merging:
full OS matrix (Sindbad.jl + SindbadTEM.jl), the docs build, and Test Simulations. Results
post back to this PR as comments automatically. Re-run it after new commits; it's the last
check before merging.

(or Actions tab -> pick a workflow -> Run workflow -> select this branch, to run just one)
