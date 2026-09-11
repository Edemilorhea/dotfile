# Explorer Delegation Budget

Treat Explorer as an escalation path, not the default first step.

Do not delegate to Explorer when:

- The relevant path, file, symbol, or entry point is already known.
- The question is a single lookup that direct `glob`, `grep`, or `read` can answer.
- The likely scope is small, such as one feature area or three files or fewer.
- You need the full file contents or are about to edit the discovered files.
- One or two targeted searches can provide enough evidence to proceed.

Delegate to Explorer only when:

- The code location is genuinely unknown after direct targeted searches.
- The task requires broad discovery across multiple modules or naming conventions.
- Independent search lanes would materially reduce discovery time.
- A compressed repository map is more useful than reading the relevant files directly.

When delegating:

- Launch at most one Explorer per user request unless the user explicitly asks for exhaustive or parallel investigation.
- Give it a narrow objective, explicit search scope, and expected output.
- Request concise file paths, line numbers, and findings rather than exhaustive analysis.
- Do not request repository-wide mapping unless the user explicitly asks for it.
- Do not repeat substantially identical Explorer searches; proceed with the available evidence or ask the user for clarification.

## MVP-First Planning

When planning implementation work:

- Present the smallest viable MVP first: the minimum scope that delivers the requested outcome and can be verified.
- Keep optional hardening, safeguards, edge-case handling, scalability work, and future extensibility out of the MVP unless correctness, security, accessibility, or data integrity requires them.
- After the MVP, list recommended reinforcements or protections separately, including when each becomes necessary.
- Do not implement optional recommendations unless the user requests them or they are required for a safe and correct MVP.
