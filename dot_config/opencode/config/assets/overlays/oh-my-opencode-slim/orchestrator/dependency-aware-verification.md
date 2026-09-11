## Dependency-Aware Verification Scheduling

- Disjoint writer scopes permit parallel writes, but do not by themselves make validation independent.
- Before dispatching a check, identify every path, generated output, build artifact, and shared state that it reads, plus the writer or producer for each dependency.
- A check may run while writers are active only when its inputs and outputs are known to be isolated from every active writer. Otherwise, wait until all writers and artifact producers it depends on reach a terminal state.
- Dispatch isolated local checks as soon as their dependency scope is complete. Defer cross-scope, shared-output, build-graph, and end-to-end checks until all of their dependencies are terminal.
- Report a local pass only as evidence for that completed scope. Do not claim an integrated pass until the required integration check runs against the combined outputs.
- Run only the missing checks needed for the requested confidence. Reuse sufficient successful evidence instead of repeating equivalent validation.
