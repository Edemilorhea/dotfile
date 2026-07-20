<!-- Context: workflows/external-libraries-faq | Priority: medium | Version: 1.0 | Updated: 2026-02-05 -->
# External Libraries: FAQ

**Purpose**: Troubleshooting and common questions about ExternalScout

---

## When exactly should I use ExternalScout?

Use it when the task actively uses, changes, configures, or diagnoses an external package and a current API, version, or setup fact remains uncertain after checking local evidence.

**Typical triggers:** first-time setup, version upgrades, dependency errors, or integration changes whose required current behavior is not established locally. Mentions, imports, and package.json entries alone are not triggers.

---

## What if I already know the library?

**DON'T rely on training data - it's outdated.**

Example: You think "I know Next.js, I'll use pages/"  
Reality: Next.js 15 uses app/  
Result: Broken code ❌

Verify task-relevant current facts from installed source, lockfiles, existing verified usage, or current docs. Use ExternalScout only when local evidence does not resolve the uncertainty.

---

## How do I know if something is external?

**External:** npm/pip/gem/cargo packages | Third-party frameworks | ORMs | Auth libraries | UI libraries

**NOT external:** Your project's code | Project utilities | Internal modules

**Check:** Is the task changing or diagnosing it, and is a current fact unresolved? → Consider ExternalScout

---

## Can I use both ContextScout and ExternalScout?

Yes, when both an internal-standards path and a current-library fact are genuinely unknown. Do not call either agent when the caller already supplied sufficient evidence.

```javascript
// 1. ContextScout: Project standards
task(subagent_type="ContextScout", ...)

// 2. ExternalScout: Library docs  
task(subagent_type="ExternalScout", ...)

// 3. Combine: Implement using both
```

---

## What if ExternalScout doesn't have the library?

ExternalScout has two sources:
1. **Context7 API** (primary): 50+ popular libraries
2. **Official docs** (fallback): Any library with public docs

If library not in Context7: Auto-fallback to official docs via webfetch.

---

## How do I write a good ExternalScout prompt?

**Template:**
```javascript
task(
  subagent_type="ExternalScout",
  description="Fetch [Library] docs for [specific topic]",
  prompt="Fetch current documentation for [Library]: [specific question]
  
  Focus on:
  - [What you need - be specific]
  - [Related features/APIs]
  
  Context: [What you're building]"
)
```

**Good:** ✅ Specific | ✅ Focused (3-5 things) | ✅ Contextual
**Bad:** ❌ Vague | ❌ Too broad | ❌ No context

---

## What if I get an error after using ExternalScout?

**Process:**
1. Read error message carefully
2. ExternalScout again with specific error:
```javascript
task(
  subagent_type="ExternalScout",
  description="Fetch docs for error resolution",
  prompt="Fetch [Library] docs: [error message]
  Error: [paste actual error]
  Focus on: Common causes | Solutions"
)
```
3. Check install scripts (maybe setup incomplete)
4. Verify versions (package.json vs docs)

---

## Do I need approval to use ExternalScout?

**NO - ExternalScout is read-only, no approval required.**

**Approval required:** ❌ Write code | ❌ Run commands | ❌ Install packages
**No approval:** ✅ ContextScout | ✅ ExternalScout | ✅ Read files

---

## ContextScout vs ExternalScout?

| Aspect | ContextScout | ExternalScout |
|--------|--------------|---------------|
| **Searches** | Internal project files | External documentation |
| **Location** | `/c/Users/tc_tseng/.config/opencode/context/` | Internet (Context7, docs) |
| **Returns** | Project standards | Library APIs |
| **Use for** | "How we do things here" | "How this library works" |
| **Speed** | Fast (local) | Slower (network) |

Use only the source needed to close the identified evidence gap.

---

## Quick Checklist

Before implementing with external libraries:

- [ ] Used supplied project standards, or ContextScout only if their path was unknown?
- [ ] Checked for install scripts first?
- [ ] Resolved each concrete current-library uncertainty from local evidence or ExternalScout?
- [ ] Asked for installation steps?
- [ ] Asked for current API patterns?
- [ ] Read returned docs before coding?

**All checked? → You're doing it right! ✅**

---

## Supported Libraries

**See**: `.opencode/skills/context7/library-registry.md`

**Categories:** Database/ORM | Auth | Frontend | Infrastructure | UI | State | Validation | Testing

Not listed? ExternalScout can still fetch from official docs.

---

## Related

- `external-libraries-workflow.md` - Core workflow
- `external-libraries-scenarios.md` - Common scenarios
- `.opencode/agent/subagents/core/externalscout.md` - ExternalScout agent
