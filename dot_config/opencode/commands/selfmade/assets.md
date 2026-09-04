---
description: Manage deterministic global and project OpenCode asset profiles
agent: build
subtask: false
---

# OpenCode Assets

Run the managed asset CLI with the user's arguments:

```powershell
pwsh -NoProfile -File "$HOME/.config/opencode/scripts/opencode-assets.ps1" $ARGUMENTS
```

Rules:

1. Pass the arguments through without inventing profiles or asset IDs.
2. For mutating actions (`apply` or `remove`), show `plan` first unless the user explicitly requested that exact mutation.
3. Run project actions from the intended project root or pass `-ProjectRoot` explicitly.
4. Report the command output and any pending network or authentication requirement. Never manage credentials.
5. `list`, `plan`, and the interactive TUI expose catalog descriptions, recommendations, and prerequisites when available. Use those fields to explain selection guidance without inventing claims.

Examples:

- `/assets profiles`
- `/assets plan -Scope project -Profiles documents,repository`
- `/assets plan -Scope project -Profiles understand`
- `/assets apply -Scope project -Profiles oac,documents`
- `/assets apply -Scope project -Profiles gsd`
- `/assets apply -Scope project -Profiles ponytail`
- `/assets status -Scope project`
- `/assets doctor -Scope global -Profiles core`
