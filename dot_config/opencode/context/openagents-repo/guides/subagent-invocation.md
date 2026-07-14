<!-- Context: openagents-repo/guides | Priority: high | Version: 1.0 | Updated: 2026-02-15 -->

# Guide: Subagent Invocation

**Purpose**: How to correctly invoke subagents using the task tool  
**Priority**: HIGH - Critical for agent delegation

---

## The Problem

**Issue**: Agents trying to invoke subagents with incorrect `subagent_type` format

**Error**:
```
Unknown agent type: ContextScout is not a valid agent type
```

**Root Cause**: The `subagent_type` parameter in the task tool must match the registered agent type in the OpenCode CLI, not the file path.

---

## Correct Subagent Invocation

### Available Subagent Types

Based on the OpenCode CLI registration, use these exact strings for `subagent_type`:

**Core Subagents**:
- `"TaskManager"` - Task breakdown and planning
- `"DocWriter"` - Documentation generation
- `"ContextScout"` - Context file discovery
- `"ExternalScout"` - External library/framework documentation discovery

**Code Subagents**:
- `"CoderAgent"` - Code implementation
- `"TestEngineer"` - Test authoring
- `"CodeReviewer"` - Code review
- `"BuildAgent"` - Build validation

**System Builder Subagents**:
- `"Domain Analyzer"` - Domain analysis
- `"Agent Generator"` - Agent generation
- `"Context Organizer"` - Context organization
- `"Workflow Designer"` - Workflow design
- `"Command Creator"` - Command creation

**Utility Subagents**:
- `"Image Specialist"` - Image generation/editing

---

## Invocation Syntax

### ✅ Correct Format

```javascript
task(
  subagent_type="TaskManager",
  description="Break down feature into subtasks",
  prompt="Detailed instructions..."
)
```

### ❌ Incorrect Formats

```javascript
// ❌ Using spaced alias
task(
  subagent_type="Task Manager",
  ...
)

// ❌ Using kebab-case ID
task(
  subagent_type="task-manager",
  ...
)

// ❌ Using registry path
task(
  subagent_type=".opencode/agent/subagents/core/task-manager.md",
  ...
)
```

---

## How to Find the Correct Type

### Method 1: Check Registry

```bash
# List all subagent names
cat registry.json | jq -r '.components.subagents[] | "\(.name)"'
```

**Output**:
```
TaskManager
Image Specialist
CodeReviewer
TestEngineer
DocWriter
CoderAgent
BuildAgent
ExternalScout
Domain Analyzer
Agent Generator
Context Organizer
Workflow Designer
Command Creator
ContextScout
```

### Method 2: Check OpenCode CLI

```bash
# List available agents (if CLI supports it)
opencode list agents
```

### Method 3: Check Agent Frontmatter

Look at the `name` field in the subagent's frontmatter:

```yaml
---
id: task-manager
name: TaskManager  # ← Use this for subagent_type
type: subagent
---
```

---

## Common Subagent Invocations

### TaskManager

```javascript
task(
  subagent_type="TaskManager",
  description="Break down complex feature",
  prompt="Break down the following feature into atomic subtasks:
          
          Feature: {feature description}
          
          Requirements:
          - {requirement 1}
          - {requirement 2}
          
          Create subtask files in tasks/subtasks/{feature}/"
)
```

### Documentation

```javascript
task(
  subagent_type="DocWriter",
  description="Update documentation for feature",
  prompt="Update documentation for {feature}:
          
          What changed:
          - {change 1}
          - {change 2}
          
          Files to update:
          - {doc 1}
          - {doc 2}"
)
```

### TestEngineer

```javascript
task(
  subagent_type="TestEngineer",
  description="Write tests for feature",
  prompt="Write comprehensive tests for {feature}:
          
          Files to test:
          - {file 1}
          - {file 2}
          
          Test coverage:
          - Positive cases
          - Negative cases
          - Edge cases"
)
```

### CodeReviewer

```javascript
task(
  subagent_type="CodeReviewer",
  description="Review implementation",
  prompt="Review the following implementation:
          
          Files:
          - {file 1}
          - {file 2}
          
          Focus areas:
          - Security
          - Performance
          - Code quality"
)
```

### CoderAgent

```javascript
task(
  subagent_type="CoderAgent",
  description="Implement subtask",
  prompt="Implement the following subtask:
          
          Subtask: {subtask description}
          
          Files to create/modify:
          - {file 1}
          
          Requirements:
          - {requirement 1}
          - {requirement 2}"
)
```

---

## ContextScout Special Case

**Status**: Registered as `ContextScout` in the current configuration

The `ContextScout` subagent exists in the current configuration and should be invoked with `subagent_type="ContextScout"`.

### Fallback

If a future runtime reports `Unknown agent type: ContextScout`, use direct file operations instead:

```javascript
// ❌ This may fail
task(
  subagent_type="ContextScout",
  description="Find context files",
  prompt="Search for context related to {topic}"
)

// ✅ Use direct operations instead
// 1. Use glob to find context files
glob(pattern="**/*.md", path="/c/Users/tc_tseng/.config/opencode/context")

// 2. Use grep to search content
grep(pattern="registry", path="/c/Users/tc_tseng/.config/opencode/context")

// 3. Read relevant files directly
read(filePath="/c/Users/tc_tseng/.config/opencode/context/openagents-repo/core-concepts/registry.md")
```

---

## Fixing Existing Agents

### Agents That Need Fixing

1. **repo-manager.md** - Uses `ContextScout`
2. **opencoder.md** - Check if uses incorrect format

### Fix Process

1. **Find incorrect invocations**:
   ```bash
   grep -r 'subagent_type="subagents/' .opencode/agent --include="*.md"
   ```

2. **Replace with correct format**:
   ```bash
   # Example: Fix task-manager invocation
    # Old: subagent_type="Task Manager"
    # New: subagent_type="TaskManager"
   ```

3. **Test the fix**:
   ```bash
   # Run agent with test prompt
   # Verify subagent delegation works
   ```

---

## Validation

### Check Subagent Type Before Using

```javascript
// Pseudo-code for validation
available_types = [
  "TaskManager",
  "DocWriter",
  "TestEngineer",
  "CodeReviewer",
  "CoderAgent",
  "BuildAgent",
  "ContextScout",
  "ExternalScout",
  "Image Specialist",
  "Domain Analyzer",
  "Agent Generator",
  "Context Organizer",
  "Workflow Designer",
  "Command Creator"
]

if subagent_type not in available_types:
  error("Invalid subagent type: {subagent_type}")
```

---

## Best Practices

✅ **Use exact names** - Match registry `name` field exactly  
✅ **Check registry first** - Verify subagent exists before using  
✅ **Test invocations** - Test delegation before committing  
✅ **Document dependencies** - List required subagents in agent frontmatter  

❌ **Don't use paths** - Never use file paths as subagent_type  
❌ **Don't use IDs** - Don't use kebab-case IDs  
❌ **Don't assume** - Always verify subagent is registered  

---

## Troubleshooting

### Error: "Unknown agent type"

**Cause**: Subagent type not registered in CLI or incorrect format

**Solutions**:
1. Check registry for correct name
2. Verify subagent exists in `.opencode/agent/subagents/`
3. Use exact name from registry `name` field
4. If subagent not registered, use direct operations instead

### Error: "Subagent not found"

**Cause**: Subagent file doesn't exist

**Solutions**:
1. Check file exists at expected path
2. Verify registry entry is correct
3. Run `./scripts/registry/validate-registry.sh`

### Delegation Fails Silently

**Cause**: Subagent invoked but doesn't execute

**Solutions**:
1. Check subagent has required tools enabled
2. Verify subagent permissions allow operation
3. Check subagent prompt is clear and actionable

---

## Related Files

- **Registry**: `registry.json` - Component catalog
- **Subagents**: `.opencode/agent/subagents/` - Subagent definitions
- **Validation**: `scripts/registry/validate-registry.sh`

---

**Last Updated**: 2025-12-29  
**Version**: 0.5.1
