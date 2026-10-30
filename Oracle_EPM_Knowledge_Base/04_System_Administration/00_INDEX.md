# System Administration

> Managing EPM Cloud environments — backups, migrations, patching, monitoring, user governance, and application settings.

---

## Reading Order

| # | File | What You'll Learn |
|---|------|-------------------|
| 1 | [Administration Guide](01_Administration_Guide.md) | Key operations, backup/recovery, environment management, patching, substitution variables, Job Console, troubleshooting |

---

## Key Operations Quick Reference

| Operation | Impact Level | When |
|:---|:---|:---|
| Refresh Database | 🟡 Locks application | After any metadata change |
| Clear Cube | 🔴 Data loss | Before full data reload |
| Export Snapshot | 🟢 Non-disruptive | Daily (automated); before risky changes |
| Import Snapshot | 🔴 Overwrites artifacts | Migration; disaster recovery |
| Assign Roles | 🟡 Security change | User onboarding/offboarding |

---

**Provenance:** Merged from ChatGPT `04_System_Administration/`, Claude `15_Administration/` + `17_Debugging/` + `18_Production_Support/`, Gemini equivalents.
