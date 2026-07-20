<!-- Context: openagents-repo/guides/external-libraries-workflow | Priority: high | Version: 1.0 | Updated: 2026-01-29 -->
# Guide: External Libraries Workflow

**Purpose**: Fetch current documentation for external packages when adding agents or skills

**When to Use**: When work actively uses, changes, configures, or diagnoses an external library and its current API, version, or setup is uncertain

**Time to Read**: 5 minutes

---

## Quick Start

**Golden Rule**: Resolve concrete current-library uncertainty from verified local evidence or current documentation; package mentions and existing imports alone do not trigger research

**Process**:
1. Identify the concrete API/version/setup uncertainty
2. Check verified local scripts, lockfiles, installed source, and existing usage first
3. Use **ExternalScout** only if the uncertainty remains
4. Implement with the verified evidence

---

## When to Use ExternalScout

✅ **Use ExternalScout when**:
- Adding new agents that depend on external packages
- Adding new skills that integrate with external libraries
- First-time package setup in your implementation
- Package/dependency errors occur
- Version upgrades are needed
- Work that actively uses, changes, configures, or diagnoses an external library when its current API, version, or setup is uncertain

Existing imports or already-verified local usage do not trigger ExternalScout by themselves.

❌ **Don't rely on**:
- Training data (outdated, often wrong)
- Old documentation (APIs change)
- Assumptions about package behavior

---

## Why This Matters

**Example**: Next.js Evolution
```
Training data (2023): Next.js 13 uses pages/ directory
Current (2025): Next.js 15 uses app/ directory (App Router)

Training data = broken code ❌
ExternalScout = working code ✅
```

**Real Impact**:
- APIs change (new methods, deprecated features)
- Configuration patterns evolve
- Breaking changes happen frequently
- Version-specific features differ

---

## Workflow Steps

### Step 1: Detect External Package

**Triggers**:
- First-time setup or version upgrade needs current instructions
- A dependency error requires current behavior or compatibility data
- The task changes library integration and local evidence does not establish the required API/version/setup

**Action**: Identify which external packages are involved

**Example**:
```
User: "Add authentication with Better Auth"
→ External package detected: Better Auth
→ Proceed to Step 2
```

---

### Step 2: Check Install Scripts (First-Time Only)

**For first-time package setup**, check if there are install scripts:

```bash
# Look for install scripts
ls scripts/install/ scripts/setup/ bin/install* setup.sh install.sh

# Check package-specific requirements
grep -r "postinstall\|preinstall" package.json
```

**If scripts exist**:
- Read them to understand setup order
- Check for environment variables needed
- Identify prerequisites (database, services)
- Follow their guidance before implementing

**Why**: Scripts may set up databases, generate files, or configure services in a specific order

---

### Step 3: Fetch Current Documentation (Conditional)

**Use ExternalScout** only when the concrete uncertainty remains after checking local evidence:

```bash
# Invoke ExternalScout via task tool
task(
  subagent_type="ExternalScout",
  description="Fetch Drizzle ORM documentation",
  prompt="Fetch current documentation for Drizzle ORM focusing on:
          - Modular schema patterns
          - Next.js integration
          - Database setup
          - Migration strategies"
)
```

**What ExternalScout Returns**:
- Live documentation from official sources
- Version-specific features
- Integration patterns
- Setup requirements
- Code examples

**Supported Libraries** (18+):
- Drizzle ORM
- Better Auth
- Next.js
- TanStack Query/Router/Start
- Cloudflare Workers
- AWS Lambda
- Vercel
- Shadcn/ui
- Radix UI
- Tailwind CSS
- Zustand
- Jotai
- Zod
- React Hook Form
- Vitest
- Playwright
- And more...

---

### Step 4: Implement with Fresh Knowledge

**Now implement** using the documentation from ExternalScout:
- Follow current best practices
- Use version-specific APIs
- Apply recommended patterns
- Reference the fetched docs in your code

---

## Integration with Agent/Skill Creation

### When Adding an Agent

1. Read: `guides/adding-agent.md`
2. **If agent uses external packages**:
   - Use ExternalScout to fetch docs
   - Document dependencies in agent metadata
   - Add to registry with correct versions
3. Test: `guides/testing-agent.md`

### When Adding a Skill

1. Read: `guides/adding-skill.md`
2. **If skill uses external packages**:
   - Use ExternalScout to fetch docs
   - Document dependencies in skill metadata
   - Add to registry with correct versions
3. Test: `guides/testing-subagents.md`

---

## Common Packages in OpenAgents

| Package | Use Case | Priority |
|---------|----------|----------|
| **Drizzle ORM** | Database schemas & queries | ⭐⭐⭐⭐⭐ |
| **Better Auth** | Authentication & authorization | ⭐⭐⭐⭐⭐ |
| **Next.js** | Full-stack web framework | ⭐⭐⭐⭐⭐ |
| **TanStack Query** | Server state management | ⭐⭐⭐⭐ |
| **Zod** | Schema validation | ⭐⭐⭐⭐ |
| **Tailwind CSS** | Styling | ⭐⭐⭐⭐ |
| **Shadcn/ui** | UI components | ⭐⭐⭐ |
| **Vitest** | Testing framework | ⭐⭐⭐ |

---

## Checklist

Before implementing with external libraries:

- [ ] Identified all external packages involved
- [ ] Checked for install scripts (if first-time)
- [ ] Used verified local evidence or ExternalScout to resolve each concrete current-library uncertainty
- [ ] Reviewed version-specific features
- [ ] Documented dependencies in metadata
- [ ] Added to registry with correct versions
- [ ] Tested implementation thoroughly
- [ ] Recorded the relevant source in the implementation report when it materially affects the change

---

## Related Guides

- `guides/adding-agent.md` - Creating new agents
- `guides/adding-skill.md` - Creating new skills
- `guides/debugging.md` - Troubleshooting (includes dependency issues)
- `guides/updating-registry.md` - Registry management

---

## Key Principle

> **External libraries change constantly. Verify facts that matter to the task, but do not create research work from package mentions or already-established local usage.**
