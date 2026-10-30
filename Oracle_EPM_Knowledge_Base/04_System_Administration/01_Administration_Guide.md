# System Administration

> **Prerequisites:** [EPM Architecture](../00_Foundation/02_EPM_Architecture.md), [Security and Access](../01_Security_and_Access/01_Access_Control_and_Roles.md)  
> **Sources merged:** ChatGPT 04_System_Administration, Claude 15_Administration + 17_Debugging + 18_Production_Support, Gemini equivalents  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## Key Administrative Operations

| Operation | Command / Path | Purpose | Impact |
|:---|:---|:---|:---|
| **Refresh Database** | Application → Actions → Refresh | Compile relational metadata into Essbase outline | **Locks application** — no user saves during refresh |
| **Clear Cube** | Application → Actions → Clear Cube | Remove data blocks (all, upper-level, or dynamic calc cache) | Data loss — irreversible without backup |
| **Export/Import Snapshot** | Navigator → Migration | Full or partial backup of application artifacts | Foundation of DR and migration |
| **Manage Users** | Navigator → Tools → Access Control | Add/remove users, assign roles | Security-critical |
| **Job Console** | Navigator → Monitor → Job Console | Monitor running/completed jobs, view errors | Troubleshooting |
| **Audit Reports** | Navigator → Tools → Audit | Track user actions, data changes, login history | Compliance (SOX) |

---

## Application Backup and Recovery

### Snapshot Types

| Type | Includes | Use Case |
|:---|:---|:---|
| **Maintenance Snapshot** | Automatic nightly backup by Oracle | Disaster recovery (retained for defined period) |
| **On-Demand Snapshot** | Admin-triggered full application backup | Before risky changes; migration source |
| **LCM Export** | Selective artifact export | Migrate specific forms, rules, or dimensions |

### Backup Best Practice

```
Daily automation via EPM Automate:
  1. epmautomate exportSnapshot "Nightly_Backup_YYYYMMDD"
  2. epmautomate downloadFile "Nightly_Backup_YYYYMMDD.zip" C:\Backups
  3. Retain 30 days of local backups
  4. Test restore quarterly in a non-production environment
```

`[Recommendation]`

---

## Environment Management

### Typical Environment Setup

```
DEV (Development)     TEST (UAT/QA)        PROD (Production)
  ├── Build dims        ├── Test with users    ├── Nightly ETL
  ├── Create forms      ├── Validate data      ├── User planning
  ├── Write rules       ├── Performance test   ├── Approvals
  └── Prototype         └── Sign-off           └── Reporting
```

### Migration Between Environments

```
DEV → TEST:
  1. Export snapshot from DEV
  2. Upload to TEST
  3. Import (selective or full)
  4. Verify: dimensions, forms, rules, data, security

TEST → PROD:
  1. Freeze DEV changes
  2. Export approved snapshot from TEST
  3. Schedule maintenance window
  4. Import to PROD
  5. Verify critical forms, rules, and data loads
  6. Communicate to users
```

> [!WARNING]
> Importing a full snapshot to PROD **overwrites** all artifacts including data. For incremental changes, use selective LCM export/import of specific artifact types.

`[Oracle Documented]`

---

## Maintenance Windows and Patching

Oracle applies monthly patches to EPM Cloud environments:

| Event | Timing | Admin Action |
|:---|:---|:---|
| **Test Environment Patch** | First Friday of the month | Test critical workflows immediately |
| **Production Patch** | Third Friday of the month | Verify all integrations, scripts, and key forms |
| **Downtime** | ~1–4 hours during patch | Notify users; disable scheduled automations |

### Post-Patch Checklist

1. Verify EPM Automate scripts still work
2. Test critical business rules
3. Check Smart View connections
4. Verify Data Integration loads
5. Confirm Navigation Flows and dashboards
6. Review Oracle's monthly update notes for behavior changes

`[Oracle Documented]`

---

## Application Settings

| Setting | Options | Impact |
|:---|:---|:---|
| **Duplicate Member Names** | Enabled/Disabled | If enabled, members can share names across dimensions (uses qualified names) |
| **Aggregate Storage** | BSO/ASO per cube | Cannot change after creation |
| **Multi-Currency** | Enabled/Disabled | Cannot disable after enabling |
| **Substitution Variables** | Name=Value pairs | Used in forms, rules, and reports for dynamic references |
| **User Variables** | Per-user filter settings | Control what users see on forms (e.g., their Entity) |

### Substitution Variables

```
Variable: &CurrMonth = "Oct"
Variable: &CurrYear  = "FY26"
Variable: &PriorYear = "FY25"

Used in forms:  Column = &CurrMonth
Used in rules:  FIX(&CurrYear, &CurrMonth) ... ENDFIX
Updated monthly by automation or admin
```

`[Oracle Documented]`

---

## Monitoring and Troubleshooting

### Job Console

The Job Console shows all running and completed jobs:

| Column | Information |
|:---|:---|
| **Job Name** | Rule, data load, or system task name |
| **Status** | Processing, Completed, Error |
| **Start/End Time** | Execution duration |
| **User** | Who initiated the job |
| **Details** | Error messages, row counts, processing details |

### Common Administrative Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "Application locked" | Refresh or restructure in progress | Wait for completion; check Job Console |
| Slow form load | Too many rows, missing suppression | Enable suppression; reduce form scope |
| Business rule timeout | Calculation too complex or broad FIX scope | Narrow FIX scope; optimize rule |
| Data load partial success | Mapping errors in Data Integration | Check Workbench validation errors |
| User can't see new members | Cube not refreshed after metadata import | Run Refresh Database |
| Smart View connection fails | Patch changed endpoint or SSO config | Verify URL and authentication |

---

## Quick Recall

1. **What does Refresh Database do and why is it critical?**
   → Compiles changes from the relational metadata tables into the Essbase binary outline (.OTL). Without it, new members and property changes don't take effect.

2. **What's the difference between a maintenance snapshot and an on-demand snapshot?**
   → Maintenance snapshots are automatic nightly backups by Oracle. On-demand snapshots are admin-triggered backups you control.

3. **Why test after monthly patches?**
   → Oracle patches can change behavior, add features, or fix bugs that affect scripts, rules, integrations, and UI flows.

