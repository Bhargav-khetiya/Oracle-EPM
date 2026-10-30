# Application Lifecycle Management

> From creating a new application to migration, cloning, patching, and disaster recovery — managing the full lifecycle of an EPM Cloud application.

---

## Reading Order

| # | File | What You'll Learn |
|---|------|-------------------|
| 1 | Application Lifecycle Guide (coming) | Application creation, LCM snapshots, environment migration, cloning, patching |

---

## Lifecycle Stages

```
CREATE → DEVELOP → TEST → MIGRATE → PRODUCTION → MAINTAIN → ARCHIVE
   │         │        │       │          │            │          │
   ▼         ▼        ▼       ▼          ▼            ▼          ▼
 App      Dims,     Clone   LCM       Nightly      Patches,   Snapshot
 Wizard   Rules,    to      Export/   ETL +        Updates,   Export &
          Forms,    Test    Import    Calc          DR         Archive
          Data      Env     Snapshots Pipeline     Planning
```

## Key Tools

| Tool | Purpose |
|:---|:---|
| **LCM (Lifecycle Management)** | Export/import application artifacts as snapshots |
| **Migration** | Move artifacts between environments (Dev → Test → Prod) |
| **Clone** | Create a copy of the application for testing |
| **EPM Automate** | Script backup, migration, and maintenance tasks |

---

**Provenance:** Source material from ChatGPT `05_Application_Creation_and_Lifecycle_Management/`, Claude `19_Implementation/`, `20_Projects/`.
