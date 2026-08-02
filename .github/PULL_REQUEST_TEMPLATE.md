## Summary

<!-- What does this PR change, and why? -->

## Automatic tests

Automatically, every PR runs a fast, ubuntu-only check on every push to aid the developer.
`/test-simulation` (changes under `src/`) and `/test-tem` (changes under
`SindbadTEM/src/Processes/`) also auto-run when relevant.

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

