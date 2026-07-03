# TaskManager — Enhanced Schema Reference

> Loaded on demand by `TaskManager` only when planning-agent output files are detected
> (`.tmp/tasks/{feature}/contexts.json`, `.tmp/planning/{feature}/map.json`, etc.) or when
> constructing a fully-populated Enhanced Schema example. Not needed for everyday task
> breakdown — see `task-manager.md`'s inline `line_number_precision` section for the
> commonly-used part of the schema.
>
> The planning agents referenced below (ArchitectureAnalyzer, StoryMapper,
> PrioritizationEngine, ContractManager, ADRManager) are part of OAC's advanced profile
> and may not be installed. If their expected input files don't exist, skip this file
> entirely — all enhanced fields are optional and task creation proceeds without them.

## Planning Agent Integration

### ArchitectureAnalyzer

- **Input file**: `.tmp/tasks/{feature}/contexts.json`
- **Fields extracted**: `bounded_context` (DDD bounded context, e.g. "authentication", "billing"), `module` (package name, e.g. "@app/auth", "payment-service")
- **Usage**: Load contexts.json → extract `bounded_context` for task.json → map subtasks to appropriate bounded contexts → set `module` per subtask based on context mapping.

### StoryMapper

- **Input file**: `.tmp/planning/{feature}/map.json`
- **Fields extracted**: `vertical_slice` (feature slice identifier, e.g. "user-registration", "checkout-flow")
- **Usage**: Load map.json → extract `vertical_slice` identifiers → map subtasks to appropriate slices → use story breakdown to inform subtask creation.

### PrioritizationEngine

- **Input file**: `.tmp/planning/prioritized.json`
- **Fields extracted**: `rice_score` (Reach, Impact, Confidence, Effort), `wsjf_score` (Business Value, Time Criticality, Risk Reduction, Job Size), `release_slice` (e.g. "v1.2.0", "Q1-2026", "MVP")
- **Usage**: Load prioritized.json → extract scores for task.json → use `release_slice` to group related tasks → order subtasks by priority scores.

### ContractManager

- **Input file**: `.tmp/contracts/{context}/{service}/contract.json`
- **Fields extracted**: `contracts` (array of API/interface contracts: type, name, path, status, description)
- **Usage**: Load contract.json files for relevant bounded contexts → extract `contracts` array for task.json → map contracts to subtasks that implement/depend on them → identify contract dependencies between subtasks.

### ADRManager

- **Input file**: `docs/adr/{seq}-{title}.md`
- **Fields extracted**: `related_adrs` (array of ADR references: id, path, title, decision)
- **Usage**: Search `docs/adr/` for relevant architectural decisions → extract `related_adrs` for task.json → map ADRs to subtasks that must follow those decisions → include ADR constraints in acceptance criteria.

## Fully-Populated Example: task.json

```json
{
  "id": "user-authentication",
  "name": "User Authentication System",
  "status": "active",
  "objective": "Implement JWT-based authentication with refresh tokens",
  "context_files": [
    {
      "path": "{context_root}/core/standards/code-quality.md",
      "lines": "53-95",
      "reason": "Pure function patterns for auth service"
    },
    {
      "path": "{context_root}/core/standards/security-patterns.md",
      "lines": "120-145",
      "reason": "JWT validation rules"
    }
  ],
  "reference_files": ["src/middleware/auth.middleware.ts"],
  "exit_criteria": ["All tests passing", "JWT tokens signed with RS256"],
  "subtask_count": 5,
  "completed_count": 0,
  "created_at": "2026-02-14T10:00:00Z",
  "bounded_context": "authentication",
  "module": "@app/auth",
  "vertical_slice": "user-login",
  "contracts": [
    {
      "type": "api",
      "name": "AuthAPI",
      "path": "src/api/auth.contract.ts",
      "status": "defined",
      "description": "REST endpoints for login, logout, refresh"
    }
  ],
  "related_adrs": [
    {
      "id": "ADR-003",
      "path": "docs/adr/003-jwt-authentication.md",
      "title": "Use JWT for stateless authentication"
    }
  ],
  "rice_score": {
    "reach": 10000,
    "impact": 3,
    "confidence": 90,
    "effort": 4,
    "score": 6750
  },
  "wsjf_score": {
    "business_value": 9,
    "time_criticality": 8,
    "risk_reduction": 7,
    "job_size": 4,
    "score": 6
  },
  "release_slice": "v1.0.0"
}
```

## Fully-Populated Example: subtask_NN.json

```json
{
  "id": "user-authentication-02",
  "seq": "02",
  "title": "Implement JWT service with token generation and validation",
  "status": "pending",
  "depends_on": ["01"],
  "parallel": false,
  "context_files": [
    {
      "path": "{context_root}/core/standards/code-quality.md",
      "lines": "53-72",
      "reason": "Pure function patterns"
    },
    {
      "path": "{context_root}/core/standards/security-patterns.md",
      "lines": "120-145",
      "reason": "JWT signing and validation rules"
    }
  ],
  "reference_files": ["src/config/jwt.config.ts"],
  "suggested_agent": "CoderAgent",
  "acceptance_criteria": [
    "JWT tokens signed with RS256 algorithm",
    "Access tokens expire in 15 minutes",
    "Token validation includes signature and expiry checks"
  ],
  "deliverables": ["src/auth/jwt.service.ts", "src/auth/jwt.service.test.ts"],
  "bounded_context": "authentication",
  "module": "@app/auth",
  "contracts": [
    {
      "type": "interface",
      "name": "JWTService",
      "path": "src/auth/jwt.service.ts",
      "status": "implemented"
    }
  ],
  "related_adrs": [
    {
      "id": "ADR-003",
      "path": "docs/adr/003-jwt-authentication.md"
    }
  ]
}
```
