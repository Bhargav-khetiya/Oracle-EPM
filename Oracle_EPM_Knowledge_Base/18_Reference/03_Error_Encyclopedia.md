# Error Encyclopedia — Common EPM Errors and Solutions

> **Section:** 18 — Reference  
> **File:** 03 — Error Encyclopedia  
> **Difficulty:** All Levels

---

## How to Use This Reference

When you encounter an error in Oracle EPM Cloud, find the error code or symptom below. Each entry includes the error message, root cause, and step-by-step fix.

---

## Essbase Calculation Errors

### "Member not found" / "Unknown member name"

**Error:** `1200502 — Error parsing formula at ...`

**Cause:** The member name in your calc script doesn't match any member in the outline. Common reasons:
- Typo in member name
- Member was renamed or deleted
- Member not yet deployed (needs Database Refresh)

**Fix:**
1. Check the member name spelling in the outline (Navigator → Dimensions)
2. If recently added, run Database Refresh
3. If the member name contains spaces, enclose in double quotes: `"My Member"`

---

### "Block not writable" / SET LOCKBLOCK conflict

**Error:** Calculation appears to run but no data changes.

**Cause:** Another process has locked the blocks your calculation needs, or `SET LOCKBLOCK ON` is left enabled from a previous rule.

**Fix:**
1. Check Job Console for concurrent running rules
2. Ensure `SET LOCKBLOCK OFF` at the end of your calc script
3. Wait for other rules to complete before rerunning

---

### Block explosion (database grows rapidly)

**Symptom:** Database size increases dramatically after running a rule.

**Cause:** `SET CREATEBLOCKONEQ ON` is enabled globally or within a broad FIX scope, creating blocks for every sparse intersection.

**Fix:**
1. Only enable `SET CREATEBLOCKONEQ ON` within a targeted FIX
2. Turn it OFF immediately after: `SET CREATEBLOCKONEQ OFF;`
3. Run `CLEARBLOCK ALL;` to remove empty blocks if damage occurred

---

## Data Integration Errors

### EPMIE-00070 — Import conflict

**Error:** `EPMIE-00070: An artifact with the same name already exists`

**Cause:** Importing a snapshot that contains artifacts matching existing artifacts in the target application.

**Fix:** Use "Create or Update" import mode instead of "Create" mode. This allows existing artifacts to be overwritten.

---

### Data load rejected — "Invalid member"

**Symptom:** Data loads partially; rejection file shows "Invalid member" for some rows.

**Cause:** The source data file contains member names that don't exist in the outline.

**Fix:**
1. Check the rejection file for specific member names
2. Add missing members to the outline, or
3. Create mappings in Data Management to transform source names

---

## Lifecycle Management Errors

### EPMLCM-26000 — Snapshot compatibility

**Error:** `EPMLCM-26000: Import failed due to version mismatch`

**Cause:** The snapshot was exported from a different EPM Cloud version than the target.

**Fix:**
1. Ensure source and target environments are on the same EPM Cloud version
2. Check Oracle's compatibility matrix for cross-version support
3. If migrating across versions, export only compatible artifacts

---

### Snapshot upload exceeds 2 GB

**Error:** Web UI upload fails with size error.

**Cause:** The web interface has a 2 GB file upload limit.

**Fix:** Use `epmautomate uploadfile "filename"` — the CLI has no size limit.

---

## Smart View Errors

### "Cannot connect to provider"

**Cause:** Network issue, incorrect URL, or expired credentials.

**Fix:**
1. Verify the connection URL format: `https://<instance>.pbcs.<dc>.oraclecloud.com/HyperionPlanning/SmartView`
2. Check credentials
3. Verify network/proxy settings
4. Clear Smart View connection cache

---

### "Ad hoc grid is disconnected"

**Cause:** Session timed out or connection was lost.

**Fix:**
1. Save local work
2. Reconnect: Smart View → Connections → Refresh
3. Re-open the form or ad hoc grid

---

## Groovy Rule Errors

### NullPointerException

**Cause:** Accessing a property on a null object (e.g., cell doesn't exist, member not found).

**Fix:** Use the safe navigation operator `?.`:
```groovy
def entity = operation.grid.pov.find { it.key == "Entity" }?.value
// Returns null instead of throwing NPE
```

---

### "Out of memory" during Groovy execution

**Cause:** Groovy rule processing too many cells or creating too many objects. Each rule has ~50 MB memory limit.

**Fix:**
1. If processing > 10,000 cells, generate a calc script instead
2. Batch DataGridBuilder writes into chunks
3. Avoid storing large collections in memory

---

### throwVetoException not showing message

**Cause:** The rule is configured as "Run on Save — After Save" instead of "Before Save."

**Fix:** Change the rule association to "Before Save" in Form Properties. Veto only works before data is committed.

---

## Performance-Related Errors

### Form retrieval timeout

**Symptom:** Form takes > 60 seconds to open and may time out.

**Cause:** Form retrieves too much data — too many rows/columns, no suppression enabled.

**Fix:**
1. Enable "Suppress missing rows" and "Suppress missing columns"
2. Reduce the number of members on rows and columns
3. Use page dimensions to filter data
4. Consider Hybrid BSO for dynamic aggregation

---

### "Maximum number of concurrent operations exceeded"

**Cause:** Too many users or automated processes running simultaneously.

**Fix:**
1. Stagger automated rule executions
2. Coordinate EPM Automate scripts to run sequentially
3. Check Job Console for queued jobs

---

## EPM Automate Errors

### "Login failed — invalid credentials"

**Fix:**
1. Verify username and password
2. Check if MFA is enabled (use encrypted password file: `.epw`)
3. Ensure the URL includes the correct data center

### "Command not recognized"

**Fix:** Ensure you're running the latest version of EPM Automate. Update using the download from Oracle Cloud.

---

## Source Provenance

| Source | Files |
|--------|-------|
| Claude | `31_Error_Encyclopedia/` |
| ChatGPT | `06_Automation_Runbooks_and_Troubleshooting/03_Master_Troubleshooting_FAQ_and_Gotchas.md` |
| Gemini | Troubleshooting files (mirrors ChatGPT) |
| Oracle | [Troubleshooting EPM Cloud](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/tsepm/) |

