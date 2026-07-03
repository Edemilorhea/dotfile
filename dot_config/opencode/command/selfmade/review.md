---
description: Code Review
agent: build
subtask: true
---

# Code Review

Perform comprehensive code review with language-specific expertise.

## 🎯 Auto-Detection

Automatically detect language and apply appropriate best practices:
- **.NET (.cs)** → Invoke `@dotnet-code-reviewer` for DDD/CQRS analysis
- **Python (.py)** → PEP 8, type hints, docstrings
- **TypeScript/React (.ts/.tsx)** → React patterns, hooks, type safety
- **Java (.java)** → Java conventions, design patterns
- **Other languages** → General best practices

## 📋 Review Framework

### 🔴 Critical Issues
- **Bugs**: Logic errors, null references, edge cases
- **Security**: Injection flaws, authentication issues, data exposure
- **Performance**: N+1 queries, memory leaks, inefficient algorithms
- **Architecture**: Pattern violations, tight coupling

### 🟡 Design & Architecture
- **Design Patterns**: Appropriate pattern usage
- **SOLID Principles**: Single Responsibility, Open/Closed, etc.
- **Consistency**: Alignment with project architecture
- **Scalability**: Future growth considerations

### 🔵 Code Quality
- **Readability**: Clear naming, appropriate abstraction
- **Maintainability**: Low coupling, high cohesion
- **Testability**: Dependency injection, mockable dependencies
- **Best Practices**: Language-specific conventions

### 💡 Suggestions
- **Refactoring opportunities**
- **Optimization potential**
- **Documentation improvements**

### ✅ What's Good
- Acknowledge well-implemented code
- Highlight best practices followed

### 📋 Action Items (Prioritized)
1. **[High Priority]** - Critical fixes
2. **[Medium Priority]** - Design improvements
3. **[Low Priority]** - Nice-to-have enhancements

---

**Usage Examples**:
- `/review` - Review current context
- `/review @src/components/Button.tsx` - Review specific file
- `/review @src/**/*.cs` - Review multiple files
