﻿# Oracle EPM Cloud: Copy Snapshot Between Instances (Server-to-Server)

## 1. `copySnapshotFromInstance` — Direct Server-to-Server Transfer

The `copySnapshotFromInstance` command copies a snapshot **directly** from a source EPM environment to the target environment where you're currently logged in — without downloading to your local machine first.

```
Source (Production)                    Target (Demo/Test)
       │                                      │
       │        Oracle's Internal Network      │
       │  ────────────────────────────────────► │
       │    copySnapshotFromInstance            │
       │    (server-to-server, fast)           │
       │                                      │
       │                                      ▼
       │                              Snapshot in inbox
       │                              (ready for import)
```

### Why Use This Instead of Download/Upload—

| Method | Speed | Local Disk Needed | Network Used |
|--------|-------|-------------------|-------------|
| `downloadFile` → `uploadFile` | Slow (2 hops) | ✅ Yes (full snapshot) | Your internet (2x) |
| `copySnapshotFromInstance` | **Fast** (1 hop) | ❌ No | Oracle internal network |

> [!TIP]
> For environments within Oracle's cloud, `copySnapshotFromInstance` is significantly faster than downloading and re-uploading because the data never leaves Oracle's data center.

---

## 2. Command Reference

### Syntax

```
epmautomate copySnapshotFromInstance SNAPSHOT_NAME SOURCE_USERNAME SOURCE_PASSWORD_FILE SOURCE_URL
```

| Parameter | Description | Example |
|-----------|-------------|---------|
| `SNAPSHOT_NAME` | Name of the snapshot in the **source** environment | `"Artifact Snapshot"` |
| `SOURCE_USERNAME` | Service Administrator username for the **source** | `admin@company.com` |
| `SOURCE_PASSWORD_FILE` | Path to encrypted password file for the **source** | `C:\EPM_Scripts\passwords\prod_password.epw` |
| `SOURCE_URL` | URL of the **source** environment | `https://planning-myco.epm.us1.oraclecloud.com` |

**Critical:** You must be **logged into the TARGET** environment before running this command. The command pulls from the source into where you're currently logged in.

**Required Roles:** Service Administrator on **both** source and target environments

---

## 3. Step-by-Step Usage

### Prerequisite: Create Password File for Source Environment

If you haven't already, create an encrypted password file for the source (Production):
```cmd
epmautomate encrypt "ProdPassword" "myKey" "C:\EPM_Scripts\passwords\prod_password.epw"
```

### Complete Workflow

```cmd
REM =============================================
REM  STEP 1: Login to the TARGET (Demo/Test)
REM  You must be logged into the DESTINATION
REM =============================================
epmautomate login admin@company.com "C:\EPM_Scripts\passwords\demo_password.epw" "https://planning-test-myco.epm.us1.oraclecloud.com"

REM =============================================
REM  STEP 2: Copy snapshot FROM the SOURCE (Prod)
REM  Note: You provide source credentials here
REM =============================================
epmautomate copySnapshotFromInstance "Artifact Snapshot" admin@company.com "C:\EPM_Scripts\passwords\prod_password.epw" "https://planning-myco.epm.us1.oraclecloud.com"

REM =============================================
REM  STEP 3: Verify the snapshot arrived
REM =============================================
epmautomate listFiles
REM Should show: Artifact Snapshot

REM =============================================
REM  STEP 4: Import the snapshot
REM =============================================
epmautomate importSnapshot "Artifact Snapshot" importUsers=true

REM =============================================
REM  STEP 5: Logout
REM =============================================
epmautomate logout
```

---

## 4. Copying Custom-Named Snapshots

You can copy any snapshot that exists in the source environment, not just "Artifact Snapshot":

```cmd
REM Copy a custom snapshot named "FullProdBackup"
epmautomate copySnapshotFromInstance "FullProdBackup" admin@company.com prod_pass.epw "https://planning-myco.epm.us1.oraclecloud.com"
```

> [!NOTE]
> The snapshot name must **exactly match** the name as it appears in the source environment's `listFiles` output. Names are case-sensitive.

---

## 5. Combined with Recreate — Full Migration Workflow

The most common workflow is: **Recreate Demo → Copy Snapshot from Prod → Import**

```cmd
REM =============================================
REM  Login to Demo (Target)
REM =============================================
epmautomate login admin@company.com demo_pass.epw "https://planning-test-myco.epm.us1.oraclecloud.com"

REM =============================================
REM  Recreate Demo (wipe it clean)
REM =============================================
epmautomate recreate -f

REM =============================================
REM  Copy Prod snapshot to Demo
REM =============================================
epmautomate copySnapshotFromInstance "Artifact Snapshot" admin@company.com prod_pass.epw "https://planning-myco.epm.us1.oraclecloud.com"

REM =============================================
REM  Import the snapshot with users
REM =============================================
epmautomate importSnapshot "Artifact Snapshot" importUsers=true userPassword=DemoP@ss1 resetPassword=false

REM =============================================
REM  Logout
REM =============================================
epmautomate logout
```

---

## 6. Limitations and Considerations

### What `copySnapshotFromInstance` Does NOT Transfer

| Item | Included— | Alternative |
|------|-----------|-------------|
| Application artifacts (metadata, data, forms, rules) | ✅ Yes | — |
| Security (groups, role assignments) | ✅ Yes (in snapshot) | Import with `importUsers=true` |
| Audit data | ❌ No | Use `cloneEnvironment` |
| Job Console history | ❌ No | Use `cloneEnvironment` |
| Data Management staging tables | ❌ No | Use `exportDataManagement` / `importDataManagement` or `cloneEnvironment` |
| Inbox/Outbox files (other than the snapshot) | ❌ No | Manually copy or use `cloneEnvironment` |

### When to Use `copySnapshotFromInstance` vs. Other Methods

| Use `copySnapshotFromInstance` when... | Use `cloneEnvironment` when... | Use `downloadFile`/`uploadFile` when... |
|----|----|-----|
| You want control over what to import | You want a complete, identical copy | You need a local copy of the snapshot |
| You don't need audit/DM staging data | You need audit, job console, DM data | Network between environments is slow |
| You want to import selectively | You want one-click full replication | You want to archive snapshots locally |
| Environments are on different patch versions | Both must be on same patch version | Any situation |

> [!WARNING]
> **Cross-region transfers:** If your source and target environments are in **different Oracle Cloud regions** (e.g., US1 → EU1), the copy may take longer than expected because data must traverse Oracle's inter-region network.

---

## 7. Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| `EPMCSS-20187: Invalid credentials` | Wrong source username or password file | Verify source credentials |
| `EPMCSS-20189: Could not connect to URL` | Wrong source URL | Verify source environment URL |
| `Snapshot not found` | Snapshot name doesn't exist in source | Run `listFiles` on source to verify name |
| `Session timeout` | Copy took too long | Increase timeout or try again |
| `User not authorized` | Missing Service Admin on source or target | Verify roles on both environments |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: How does copySnapshotFromInstance achieve 10x faster transfer speeds than download and upload—
**Answer:** copySnapshotFromInstance streams data **server-to-server** across Oracle's internal 100 Gbps cloud backbone network. It establishes a secure mutual-TLS tunnel directly between the source pod and target pod. No data flows through the administrator's local computer or corporate VPN, eliminating local network latency and bandwidth bottlenecks.

### Q2: Does copySnapshotFromInstance consume local disk space on the administrator's workstation—
**Answer:** Zero bytes of local disk space are consumed. The command executed locally is merely a 1 KB control signal. The snapshot archive streams directly from the source environment's cloud storage into the target environment's Inbox.

### Q3: What happens if the target environment already has a snapshot with the exact same name—
**Answer:** The incoming snapshot will overwrite the existing file in the target environment's Inbox without warning. If you need to preserve the target snapshot, use epmautomate renameFile to archive the target copy before initiating the cross-pod transfer.
