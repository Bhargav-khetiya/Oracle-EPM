# Oracle EPM Cloud: Troubleshooting and FAQ

## 1. Common Errors and Resolutions

### Authentication Errors

| Error Code | Error Message | Cause | Resolution |
|-----------|---------------|-------|------------|
| `EPMCSS-20187` | Invalid credentials | Wrong username or password | Re-create the `.epw` password file; verify username is correct email |
| `EPMCSS-20189` | Could not connect to URL | Wrong URL, network issue, or VPN disconnected | Verify URL format; check VPN/proxy; try in browser first |
| `EPMCSS-20149` | Session already active | Previous session wasn't closed | Run `epmautomate logout` first, then try again |
| `EPMCSS-20071` | Password file not found | Wrong path to `.epw` file | Check file path exists; use full absolute path; use quotes if path has spaces |
| `EPMCSS-20xxx` | User is not authorized | Missing required role | Verify user has Service Administrator role in Identity Domain |

### Recreate Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| Recreate hangs / never completes | Large environment or system issue | Wait longer (up to 1 hour); if still stuck, contact Oracle Support |
| "Environment is in use" | Users or jobs active | Ensure all users are signed out; check Job Console for running jobs |
| TempServiceType not recognized | Wrong service type code | Use exactly: `ARCS`, `EDMCS`, `EPRCS`, or `PCMCS` |
| Cannot recreate during maintenance | Daily maintenance is running | Wait for maintenance to complete, then retry |

### Import Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `EPMIE-00070: Failed to find user` | User in snapshot not in target Identity Domain | Use `importUsers=true` to create missing users |
| Import fails on seeded period member | Renamed seeded member conflicts with custom member | See "Seeded Period Member Conflict" below |
| Import takes extremely long | Shared members before base members | Normal behavior — Oracle makes multiple loading passes; wait |
| Snapshot not found | Wrong name or not in default location | Run `listFiles` to verify exact name; ensure upload completed |
| Identity domain import fails | User is not Identity Domain Admin | Assign Identity Domain Administrator role |

### Clone Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| Clone fails — version mismatch | Prod and Test on different patch versions | Wait until both are on the same version; use Approach B (snapshot) instead |
| Clone timeout | Very large environment | Retry; consider excluding DM/audit data for speed |
| "Cannot connect to target" | Wrong target URL or credentials | Verify target URL and password file |

### Restore Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| Backup not found | Backup older than ~60 days | Oracle only retains ~60 days; you need a locally downloaded copy |
| restoreEnvironment fails | Using Artifact_Snapshot.zip name | Must use Environment_Backup, not Artifact_Snapshot.zip |
| restoreBackup fails | Wrong backup name format | Use exact name from `listBackups` output, including path |

---

## 2. Known Issues and Edge Cases

### Seeded Period Member Conflict

**Problem:** Import fails when a seeded period member (e.g., `YearTotal`) has been renamed (e.g., to `unused_YearTotal`) and a custom member with the original name (`YearTotal`) has been created.

**Resolution:**
1. In the source environment, rename the custom member to a temporary name
2. Re-export the snapshot
3. Import into the target
4. After import, rename the member back
5. Or contact Oracle Support for assistance

### Role Addition (Not Replacement) During Import

**Problem:** After importing with `importUsers=true`, users have **extra roles** they shouldn't have.

**Explanation:** Import only **adds** roles — it never removes existing ones. If a user has Power User in the target but only User in the snapshot, they'll end up with both.

**Resolution:**
1. Manually review and adjust roles after import via **Tools → Access Control**
2. Or recreate the environment first (which clears role assignments) before importing

### Data Management Connections After Migration

**Problem:** After cloning or importing, Data Management integrations point to the source (Production) environment URLs.

**Resolution:**
1. Navigate to **Data Management → Setup → Target Application**
2. Update connection URLs to point to the target (Demo) environment
3. Re-register connections if needed
4. Test by running a data load rule

### Substitution Variables

**Problem:** After migration, substitution variables reflect Production values (e.g., `CurMonth = Oct2026`) which may not be appropriate for Demo.

**Resolution:**
1. Navigate to **Tools → Variables → Substitution Variables**
2. Update any variables that should differ in Demo
3. Or script the update via EPM Automate:
   ```cmd
   epmautomate setSubstVar Plan1 CurMonth "Oct2026_TEST"
   ```

---

## 3. Frequently Asked Questions

### Q1: Can I clone from Test to Production?

**A:** Yes, `cloneEnvironment` works in both directions. You can clone from Test→Prod or Prod→Test. Just ensure you're logged into the **source** and providing **target** credentials.

> [!CAUTION]
> Cloning TO Production is extremely dangerous. Triple-check everything. One mistake could overwrite live business data.

---

### Q2: How long does Oracle keep backups in Object Storage?

**A:** Approximately **60 days**. After that, backups are automatically purged. Always maintain your own archive for critical snapshots.

---

### Q3: Can I selectively import only specific artifacts from a snapshot?

**A:** Not via EPM Automate. To selectively import:
1. Upload the snapshot to the environment
2. Go to **Navigator → Migration**
3. Click the snapshot
4. Select only the specific artifacts you want to import
5. Click **Import**

The Migration UI provides a tree view of all artifacts in the snapshot, letting you cherry-pick exactly what to import.

---

### Q4: Does recreate delete users from the Identity Domain?

**A:** **No.** `recreate` deletes the application, database, and data. User accounts in the Identity Domain are NOT affected. Users will still exist but won't have an application to access until you create or import one.

---

### Q5: Can I clone during the patch blackout period?

**A:** **No.** During the ~2-week period between Test patching (1st Friday) and Prod patching (3rd Friday), the environments are on different versions and cloning is blocked.

**Workaround:** Use the snapshot copy approach:
```cmd
epmautomate login user demo_pass.epw demo_url
epmautomate recreate -f
epmautomate copySnapshotFromInstance "Artifact Snapshot" user prod_pass.epw prod_url
epmautomate importSnapshot "Artifact Snapshot" importUsers=true
epmautomate logout
```

---

### Q6: What happens if my clone or import fails mid-way?

**A:** The target environment may be in an inconsistent state. Options:
1. **Retry** — run the command again
2. **Recreate + retry** — `recreate -f` then start over
3. **Restore from backup** — use the Demo backup you took before starting

This is why **always backing up the target before migration** is critical.

---

### Q7: Can I run EPM Automate commands while users are working?

**A:** Some commands (like `listFiles`, `listBackups`) are safe. However:
- `recreate` — **NO**, kicks everyone out and destroys the app
- `cloneEnvironment` — **NO**, target environment is overwritten
- `importSnapshot` — **Not recommended**, can cause data conflicts
- `runDailyMaintenance` — **NO**, environment goes offline

Always ensure no users are active before running destructive commands.

---

### Q8: Do I need separate EPM Automate installations for each environment?

**A:** **No.** A single EPM Automate installation can connect to any environment. You just use different URLs and password files when logging in. However, you can only be logged into **one environment at a time** per session.

---

### Q9: My snapshot is very large. How can I speed up the process?

**A:** Several strategies:

1. **Use `cloneEnvironment`** — server-to-server, fastest transfer
2. **Skip non-essential data** — set `DataManagement=false`, `appAudit=false`, `jobConsole=false`
3. **Use `copySnapshotFromInstance`** — faster than download+upload
4. **Create a partial snapshot** — via Migration UI, export only what you need
5. **Run during off-peak hours** — Oracle's network is faster when less loaded
6. **Check for unnecessary data** — clear old data, unused dimensions, or legacy content before taking the snapshot

---

### Q10: I need to change my environment from Planning to FreeForm. How?

**A:** Planning and FreeForm share the same base service type. When you `recreate`, you get a clean environment where you can create either type:

```cmd
epmautomate login user pass.epw url
epmautomate recreate -f
epmautomate logout
```

After recreate, log in via the UI and you'll be prompted to create a new application — choose **FreeForm** instead of Planning Modules.

Or import a FreeForm snapshot:
```cmd
epmautomate importSnapshot "FreeFormSnapshot"
```

---

### Q11: Can I have more than two environments (Prod + Test)?

**A:** Oracle provisions two environments by default (Production + Test). If you need additional environments (e.g., a dedicated Demo or Development):

1. **Purchase additional environments** from Oracle
2. **Request a secondary environment** through Oracle Support
3. **Use the Test environment** creatively — clone Prod to Test for testing, then recreate for development

Most organizations work with just Prod + Test and use cloning to alternate between "testing" and "demo" purposes.

---

## 4. EPM Automate Return Codes

| Return Code | Meaning |
|-------------|---------|
| `0` | Success |
| `1` | General error |
| `2` | Invalid command or parameters |
| `3` | Authentication error |
| `4` | Network / connection error |
| `5` | Server-side error |

Use these in batch scripts for error handling:
```batch
call epmautomate someCommand
IF %ERRORLEVEL% NEQ 0 (
    echo Command failed with error code %ERRORLEVEL%
    goto :ERROR
)
```

---

## 5. Quick Reference — Command Cheat Sheet

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    EPM AUTOMATE QUICK REFERENCE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  SETUP:                                                                     │
│    encrypt PASSWORD KEY FILE.epw        Create encrypted password file     │
│    login USER PASS.epw URL              Login to environment               │
│    logout                               End session                        │
│                                                                             │
│  EXPLORE:                                                                   │
│    listFiles                            Show inbox/outbox contents         │
│    listBackups                          Show archived backups (~60 days)   │
│                                                                             │
│  BACKUP:                                                                    │
│    runDailyMaintenance -f               Force immediate backup             │
│    exportSnapshot NAME                  Refresh a named snapshot           │
│    downloadFile "Artifact Snapshot"     Download snapshot locally          │
│                                                                             │
│  MIGRATE:                                                                   │
│    uploadFile FILE [inbox]              Upload file to environment         │
│    copySnapshotFromInstance             Copy between environments          │
│    importSnapshot NAME                  Import snapshot contents           │
│                                                                             │
│  ENVIRONMENT:                                                               │
│    recreate -f                          Wipe environment clean             │
│    recreate -f removeAll=true           Wipe everything including backups  │
│    cloneEnvironment USER PASS URL       Full environment replication       │
│                                                                             │
│  RESTORE:                                                                   │
│    restoreBackup BACKUP_NAME            Retrieve archived snapshot         │
│    restoreEnvironment BACKUP_NAME       Full environment restore           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔗 Navigation

| Direction | Document | Focus Area |
|:---|:---|:---|
| **Next → Deep Twisted Q&A** | [04_Master_Twisted_Questions_and_Deep_Architectural_Scenarios.md](./04_Master_Twisted_Questions_and_Deep_Architectural_Scenarios.md) | 50 Deep, twisted interview and architectural trap questions |
| **← Previous** | [02_Enterprise_Automation_Scripts.md](./02_Enterprise_Automation_Scripts.md) | Enterprise unattended automation scripts |
| **Section 5 Auditing** | [01_Migration_Reports_and_Compliance_Auditing.md](../05_Migration_Reports_Auditing_and_OnPrem_Transition/01_Migration_Reports_and_Compliance_Auditing.md) | Migration status reports and compliance auditing |
| **Section 1 Lifecycle**| [01_Lifecycle_Strategy_and_Overview.md](../01_Environment_Lifecycle_and_Maintenance/01_Lifecycle_Strategy_and_Overview.md) | Environment container strategy and reset |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) | Return to Master Index |


