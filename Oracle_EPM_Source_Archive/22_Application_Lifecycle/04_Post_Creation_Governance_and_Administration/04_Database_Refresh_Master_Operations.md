# 🔄 Database Refresh — The Complete Operations Guide
## Essbase Cube Synchronization, Outline Restructuring, Security Filters & Job Automation

> **Navigation:** `Home → Application → Overview → Actions (▼) → Refresh Database`  
> **Role Requirement:** Service Administrator  
> **Core Concept:** A Database Refresh is the mission-critical synchronization pipeline that compiles relational repository metadata, member formulas, and user security permissions into the active Essbase multidimensional database engines (`.otl` outlines and data blocks).

---

## 🧭 Why a Database Refresh is Mandatory

In Oracle Cloud EPM, when you edit a dimension, import a CSV metadata file, enable a module, or alter a security grant, changes are initially stored only in the **relational application repository**. The Essbase calculation cubes remain unaware of these changes until you execute a **Database Refresh**.

```
┌───────────────────────────────────────┐
│   Relational Metadata Repository      │
│   (Dimensions, Members, Roles, Forms) │
└──────────────────┬────────────────────┘
                   │
                   │ 🔄 DATABASE REFRESH PIPELINE
                   ▼
┌───────────────────────────────────────┐
│       Essbase Cube Engine             │
│  ├── Active Outline Files (*.otl)    │
│  ├── Multidimensional Index (*.ind)   │
│  ├── Stored Data Blocks (*.pag)       │
│  └── Compiled Security Filters        │
└───────────────────────────────────────┘
```

---

## 🖥️ Screen Layout & Refresh Options Dialog

Initiating a refresh from `Application → Overview → Actions → Refresh Database` launches the configuration dialog:

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│ Refresh Database Options                                                              ✖ │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│ Operation Targets:                                                                      │
│   ☑ Validate Metadata                                                                   │
│       Scans dimension trees for circular references, duplicate members, and             │
│       formula syntax errors prior to pushing changes to Essbase.                        │
│                                                                                         │
│   ☑ Refresh Database                                                                    │
│       Recompiles Essbase outlines (*.otl) and restructures cubes.                       │
│                                                                                         │
│   ☑ Create/Update Security Filters                                                      │
│       Translates Access Control user grants and member security into native             │
│       Essbase cell-level security filters.                                              │
│                                                                                         │
│ In-Flight User Access:                                                                  │
│   🔘 Keep application available to all users                                            │
│       Users can continue querying grids; momentary read-locks applied during outline   │
│       swap. Recommended for minor member additions.                                     │
│                                                                                         │
│   🔘 Prevent all users except Service Administrators from accessing the application     │
│       Enforces strict maintenance mode. Kicks off non-admin active sessions to          │
│       prevent transaction deadlocks. Mandatory for major restructuring.                │
│                                                                                         │
│                                                   [ Refresh ]            [ Cancel ]     │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## ⚙️ The 3 Internal Phases of a Database Refresh

When you click **[ Refresh ]**, the execution engine advances through three deterministic phases:

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│ Phase 1: Relational Compilation & Metadata Validation                                   │
│ • Validates member names against Essbase reserved word tables                           │
│ • Evaluates member formulas for syntax validity and correct function arguments          │
│ • Verifies that all shared members have valid primary stored prototypes                 │
└───────────────────────────────────────────┬─────────────────────────────────────────────┘
                                            │
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│ Phase 2: Essbase Cube Restructure & Outline Generation                                  │
│ • Re-indexes dimension hierarchies in memory                                            │
│ • Sparse Restructure: Fast index rebuild without moving data blocks                     │
│ • Dense Restructure: Full rewrite of *.pag data files (takes longer if block modified)  │
│ • Outline Swap: Atomically swaps old *.otl outline with new *.otl outline               │
└───────────────────────────────────────────┬─────────────────────────────────────────────┘
                                            │
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│ Phase 3: Security Filter Compilation & Smart List Sync                                   │
│ • Compiles cell permissions into native Essbase security filters                        │
│ • Updates member-driven Smart Lists across ASO and BSO reporting cubes                  │
│ • Releases application maintenance lock and returns status to Jobs Console              │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Restructure Types Explained: Sparse vs Dense

Understanding how Essbase physically restructures data prevents operational outages:

| Restructure Type | Triggered By | What Essbase Does | Performance Impact |
|:---|:---|:---|:---:|
| **Outline-Only** | Renaming aliases, changing non-calc properties, adding Dynamic Calc members | Updates outline metadata headers only. No data touched. | ⚡ **Instant** (Seconds) |
| **Sparse Restructure** | Adding/deleting/moving members in Sparse dimensions (Entity, Scenario, Custom) | Rebuilds the index file (`.ind`). Data blocks remain untouched. | 🚀 **Very Fast** (1–3 mins) |
| **Dense Restructure** | Adding/deleting/moving members in Dense dimensions (Account, Period), changing Dense/Sparse status | **Rewrites every single data block file (`.pag`) on disk.** | ⏳ **Heavy** (10–60+ mins for large cubes) |

> [!TIP]
> **Dense Restructure Scheduling Best Practice:**  
> Avoid modifying Dense dimension hierarchies during normal business hours. Always schedule Dense changes (like adding accounts or altering calendar periods) during nightly maintenance windows.

---

## 🤖 Automating Database Refresh via EPM Automate & REST API

In production environments, Database Refreshes are automated using command-line scripts following metadata integrations.

### Method 1: EPM Automate Command Line

```bash
# Authenticate
epmautomate login admin@company.com "Password123" https://epm-target.oraclecloud.com epmeur

# Execute database refresh
# Parameters:
# - stopAllUsers: Kick off non-admin users (true/false)
# - validateMetadata: Validate integrity before pushing (true/false)
epmautomate refreshcube validateMetadata=true stopAllUsers=false

# Check command status code
if [ $? -eq 0 ]; then
    echo "Database refresh succeeded!"
else
    echo "Database refresh failed. Inspecting jobs console..."
fi

# Sign out
epmautomate logout
```

### Method 2: REST API Web Service Call

```http
POST /HyperionPlanning/rest/v3/applications/PlanCorp/jobs HTTP/1.1
Host: epm-target.oraclecloud.com
Authorization: Basic YWRtaW5AY29tcGFueS5jb206UGFzc3dvcmQxMjM=
Content-Type: application/json

{
    "jobType": "CUBE_REFRESH",
    "jobName": "Nightly_Cube_Refresh",
    "parameters": {
        "validateMetadata": true,
        "stopAllUsers": false
    }
}
```

---

## 🚨 Troubleshooting Common Database Refresh Failures

### 1. `Error: Member formula syntax error on member [XYZ]`
- **Cause:** Typo in calculation formula, missing semicolon, unquoted member name containing hyphens, or reference to a non-existent member.
- **Resolution:** Navigate to `Application → Overview → Dimensions`, locate member `XYZ`, click Edit, fix formula syntax, click Save, and re-run refresh.

### 2. `Error: The shared member [XYZ] does not have a primary prototype`
- **Cause:** A member is designated as `Shared`, but its base stored prototype was deleted or renamed.
- **Resolution:** Locate the primary member in the hierarchy and confirm it is stored, or delete the orphaned shared member.

### 3. `Error: Cube is locked by another running process`
- **Cause:** An active business rule, data import job, or long-running user calculation is currently writing to the cube.
- **Resolution:** Navigate to `Application → Jobs`, identify and kill the long-running process, or re-run refresh selecting **"Prevent all users except Service Administrators"**.

### 4. `Error: Essbase Block Size exceeds limit`
- **Cause:** Too many dense dimension members resulted in an internal Essbase data block size greater than the recommended 2 MB threshold.
- **Resolution:** Convert non-essential dense members or convert an entire dense dimension to Sparse.

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What are the 3 distinct phases executed during a Database Refresh?
**Answer:**
1. **Phase 1: Validation & Outline Synchronization:** Validates metadata formulas and updates physical Essbase outline files (`.otl`).
2. **Phase 2: Database Restructure:** Restructures data blocks on disk if dense dimensions were modified.
3. **Phase 3: Security & Filter Deployment:** Compiles user security filters, valid intersection matrices, and cell-level security rules into Essbase memory.

### Q2: What is the difference between an Outline Restructure (Sparse) and a Full Restructure (Dense)?
**Answer:**
- **Sparse Restructure:** Occurs when adding/moving sparse members. Modifies only the outline header file; takes seconds.
- **Dense Restructure:** Occurs when adding/moving dense members or toggling dense/sparse properties. Essbase must physically read and rewrite every single data block on disk (`.pag` files); takes hours on large databases and requires 2x disk space for temporary shadow files.

### Q3: How do you automate Database Refreshes in nightly unattended DevOps pipelines?
**Answer:** Execute in your automation batch pipeline:
```cmd
epmautomate refreshCube
```
Monitor the return code. If the exit code is `0`, the refresh succeeded.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [03_Dimension_Management.md](./03_Dimension_Management_and_Member_Properties.md) |
| **Next →** | [05_Cube_and_Storage_Management.md](./05_Cube_and_Storage_Management.md) |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) |
