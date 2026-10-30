# EPM Automate

> EPM Automate is Oracle's CLI for automating every EPM Cloud administration task — from nightly data loads and metadata imports to backups, business rule execution, and security auditing.

---

## Reading Order

| # | File | What You'll Learn |
|---|------|-------------------|
| 1 | [EPM Automate Complete Guide](01_EPM_Automate_Complete_Guide.md) | Architecture, installation, authentication, all commands, scripting, scheduling, troubleshooting |

---

## Architecture

```
CLI Command ──► REST API Call ──► EPM Cloud Gateway ──► Application Server
                (JSON/HTTPS)         (OCI IAM)            (Planning/Essbase)
```

## Command Categories

| Category | Key Commands |
|:---|:---|
| **Session** | `login`, `logout` |
| **File** | `uploadFile`, `downloadFile`, `deleteFile`, `listFiles` |
| **Metadata** | `importMetadata`, `exportMetadata`, `refreshCube` |
| **Data** | `importData`, `exportData`, `runDataRule`, `runDataMap`, `clearCube` |
| **Calculations** | `runBusinessRule`, `runRuleSet`, `runJob` |
| **Backup** | `exportSnapshot`, `importSnapshot`, `copySnapshotFromInstance` |
| **Security** | `exportUsers`, `userAccessReport`, `userAuditReport`, `assignRole` |

## Typical Nightly Sequence

```
login → exportSnapshot → uploadFile → importMetadata → refreshCube
→ runDataRule → runBusinessRule → runDataMap → logout
```

---

**Provenance:** Merged from ChatGPT `EPM_Automate/` (6 files), Claude `14_EPM_Automate/`, Gemini equivalents. See [MERGE_MAP.md](../MERGE_MAP.md).
