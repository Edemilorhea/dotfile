---
name: cross-review
description: "Cross review code using a subagent with a specified model. Use when the user asks to review code changes AND specifies a model to use (e.g., 'review with opus', 'use sonnet to review', 'review changes with gemini'). The root agent reconstructs what changed from its own conversation history and gives the selected model a self-contained review contract; no review skill or git command is required."
metadata:
  version: 1.2.1
---

# Cross Review

Reconstruct what you changed during this conversation, then delegate the actual review to one subagent running the user-specified model under the contract below.

IMPORTANT: Steps 1–2 run in the current agent (the master). Only Step 3 spawns a subagent. Do NOT spawn a subagent to execute this skill's workflow — that creates unnecessary nesting.

## Expected Prompt Format

```
Use review skill with <model-id> model to review the changes. Review instructions: <instructions>
```

## Workflow

### Step 1: Parse the user request

Extract from the user's prompt:
- **Model**: The model ID to use for the subagent. Validate against the available models.
- **Review instructions**: Any text after "Review instructions:" — pass these verbatim to the subagent.
- **Change scope**: Any indication of what should be reviewed. If not provided, default to reviewing all changes made by you during this conversation.

### Step 2: Gather context from your own changes

Collect all information the review subagent will need. Do this in the current agent — do NOT delegate this step.

You already know what you changed — reconstruct the diff from your own conversation history:

1. **Reconstruct the changes**: Compose a unified diff-style summary of all changes you made by Edit, Write, Bash, and other tools you called during this conversation. Group changes by file.

   **If no changes were made**: Inform the user that no changes were found in this conversation and stop.

2. **Create a unique temp directory and save the diff there**: Create a unique temporary directory for this review session and use it for generated files.

   ```bash
   # macOS / Linux / Git Bash on Windows
   TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/cross-review-XXXXXXXX")
   ```

   If `mktemp` is not available (for example, native Windows without Git Bash), create a temporary directory with PowerShell and capture its full path before continuing.

   Write the reconstructed unified diff to `$TEMP_DIR/cross-review-diff.patch` using an available file-editing tool. The reviewer reads this file before inspecting supporting context.

3. **Read the final state of changed files** to provide full surrounding context. Use the Read tool on each changed file.

4. **Check for related context**:
   - Read test files related to the changed files, prioritizing nearby paths and excluding dependency/vendor directories (e.g., `node_modules`, `.git`, `dist`, `build`, `coverage`)
   - Check for configuration changes that may affect behavior
   - Note any related type definitions or interfaces

Do NOT show gathered context or its process to the user. Use it only for the subagent.

### Step 3: Spawn the review subagent

Use `spawn_subagent` with:
- **model**: The model extracted from the user's request.
- **prompt**: use following template

```
You are a read-only code reviewer. The diff is saved at {temp_dir}/cross-review-diff.patch. Substitute `{temp_dir}` with the real temp directory path from Step 2 before spawning the subagent. Your FIRST action MUST be to read that file. Do not run git commands and do not modify files.

Review only defects introduced by the supplied changes. Prioritize correctness and security, then behavioral regressions, missing tests, performance, and maintainability. Every finding must be concrete, actionable, and supported by a file and line. Ignore pre-existing issues and speculative repository-wide improvements. Return only a JSON array in this form:

[{"path":"...","line":0,"body":"...","severity":"P0|P1|P2|P3"}]

## Review Instructions

{user's review instructions, verbatim}

## Additional Context

{links to any related files, test files, type definitions, or user-provided requirements}
```

### Step 4: Format and relay the result — READ-ONLY, NO ACTIONS

The review subagent returns findings as a JSON array:
```json
[{"path": "...", "line": ..., "body": "...", "severity": "P0|P1|P2|P3"}]
```

Format the JSON into a human-readable review before relaying to the user:

```
## Code Review

**Verdict**: [APPROVE if no P0/P1 findings | REQUEST CHANGES if P0/P1 exist]

### Summary
[1-2 sentences: what the changes do and overall assessment based on findings]

### Findings

| Priority | Issue | Location |
|----------|-------|----------|
| P0 | {body summary} | {path}:{line} |
| ... | ... | ... |

### Details

#### [severity] Issue
**File:** `{path}:{line}`

{body}

(Repeat for each P0/P1 finding. P2/P3 items only need the table entry.)

### Recommendation
[Concise actionable recommendation for the author]
```

If the subagent returns `[]` (no findings), output:
```
## Code Review

**Verdict**: APPROVE

No issues found.
```

CRITICAL constraints:
- Do NOT act on the review: Do NOT fix, improve, or modify any code based on findings.
- Do NOT add your own commentary on the findings beyond formatting.
- A one-line model attribution (e.g., "Review produced by opus-4-6-think") is acceptable.
- You can ONLY suggest or offer to implement recommendations. Let the user decide.

## Error Handling

- **`spawn_subagent` fails or times out**: Inform the user of the failure. Suggest retrying or using a different model.
- **No changes in conversation**: Inform the user no changes were found and stop.
- **Subagent returns an error or incomplete review**: Relay whatever was returned and note that the review may be incomplete.
