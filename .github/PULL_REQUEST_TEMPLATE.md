## Summary

<!-- What does this PR change, and why? -->

## Automatic tests

Automatically, every PR runs a fast, ubuntu-only check on every push to aid the developer.
`TestSimulations.yml` (changes under `src/`) and `SindbadTEM-benchmark.yml`'s `test-model` job
(changes under `SindbadTEM/src/Processes/`, scoped to just the approach(es) that changed) also
auto-run when relevant -- everything else, including `/test-tem`'s `test-tem`/`analyse-tem` jobs
and `/compile-os`'s full OS matrix, is on-demand only (see below).

As the last step before merging, run additional tests/ checks **when the change are final** that run on-demand triggered by the following comments in the PR:

- `/check-pr` to run the full suite of tests and checks (recommended)

Or, if certain, run just what's relevant to the changes:

- `/build-docs`: docstring or new-function changes
- `/compile-os`: changes under `src/`, `SindbadTEM/src/`, or `Project.toml` dependencies
- `/test-simulation`: changes to the core simulation run path (forward/optimization) outside `src/`
- `/test-tem`: changes to approach behavior outside `SindbadTEM/src/Processes/`


The results post automatically back to the comment in this PR as comments.

***Note that these workflows can also be run any time on any branch through:***

```Actions tab -> pick a workflow -> Run workflow -> select this branch```

