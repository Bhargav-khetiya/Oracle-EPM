# REST API for EPM Cloud

> The EPM Cloud REST API provides programmatic access to all Planning operations — enabling custom integrations, CI/CD pipelines, and mobile apps.

---

## Reading Order

| # | File | What You'll Learn |
|---|------|-------------------|
| 1 | REST API Guide (coming) | Endpoints, authentication, job management, data loading, member queries |

---

## Key Endpoints

| Endpoint Pattern | Purpose |
|:---|:---|
| `/HyperionPlanning/rest/v3/applications/{app}/` | Application root |
| `.../jobs` | Submit and monitor jobs (rules, data loads, refreshes) |
| `.../dimensions/{dim}/members` | Query dimension members |
| `.../datacells` | Read/write individual cell values |
| `.../importDataSlice` / `exportDataSlice` | Bulk data operations |

> [!NOTE]
> EPM Automate is a CLI wrapper around these REST APIs. For most automation use cases, EPM Automate is simpler. Use the REST API directly when building custom applications or when EPM Automate's command set doesn't cover your need.

---

**Provenance:** Source material from Claude `13_REST_API/`. Content to be expanded.
