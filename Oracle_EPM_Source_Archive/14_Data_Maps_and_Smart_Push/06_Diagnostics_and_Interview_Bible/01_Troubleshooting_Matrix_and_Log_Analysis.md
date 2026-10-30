# 01 Troubleshooting Matrix, Error Diagnostics, and Log Analysis

## 1. Enterprise Troubleshooting Matrix

The following matrix details the most critical failure modes encountered when managing Data Maps, Smart Push, `@XREF`, and `@XWRITE` in Oracle EPM Cloud:

| Error Code / Symptom | Root Cause Architecture | Immediate Diagnostic Step | Permanent Remediation |
| :--- | :--- | :--- | :--- |
| **`Essbase Error (1200497): Cannot write to dynamic member`** | Target cube contains a member set to **Dynamic Calc** or **Dynamic Calc and Store**. Essbase kernel prohibits writing to calculated addresses. | Check target cube outline member storage property for the rejected coordinate. | Change target member to **Store Data**, or map to a stored level 0 child member. |
| **`HTTP 504 Gateway Timeout` on Form Save** | Smart Push was configured with **"Use Form Context" UNCHECKED**. Form save triggers a full global cube data map extraction. | Inspect Form Designer -> Smart Push tab -> check whether checkbox is enabled. | Enable **Use Form Context** immediately; verify push duration drops to $< 1\text{s}$. |
| **`Essbase Error (1042006): Network error [10060]: Connection timed out`** | `@XREF` / `@XWRITE` TCP socket connection failed to reach remote Essbase agent port (1423) or ephemeral ports (32768–33768). | Run network packet trace / telnet from source host to remote agent. | Ensure firewall rules permit TCP traffic across the required port ranges. |
| **`ASO Error: Maximum number of data slices reached (256)`** | High-frequency Smart Push without automated slice maintenance. ASO cubes cap out at 256 physical slice files. | Check ASO cube properties via MaxL / Calculation Manager Database Properties. | Execute `epmautomate mergeDataSlices AppName CubeName mergeOption=all` immediately. |
| **`Data Multiplied / Doubled on Target`** | Source dimension is unmapped and no single member was selected, OR parent members were pushed into an ASO cube. | Inspect Data Map definition for unmapped source dimensions or non-level 0 inclusions. | Specify single source parent member for unmapped dimension, and enforce `ILvl0Descendants`. |
| **`Data Map marked [!] Invalid`** | Outline member referenced in Data Map was renamed, deleted, or moved during metadata refresh. | Open Data Map in UI; review highlighted red rows. | Update mapping selection to reference new or existing valid members, then save. |
| **`Lock Timeout (1200525)` during `@XWRITE`** | Multiple users or batch jobs attempting to push into identical target BSO blocks simultaneously. | Review Essbase application log (`app.log`) for blocking transaction IDs. | Replace `@XWRITE` with asynchronous Data Map or Groovy dynamic micro-push. |

---

## 2. Server Log Analysis and Diagnostic Traces

When diagnosing intermittent data synchronization failures, administrators must correlate three separate log streams:

```
+---------------------------------------------------------------------------------------------------+
|                                  LOG CORRELATION ARCHITECTURE                                     |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  1. PLANNING SYSTEM LOG (Planning_syslog.log):                                                    |
|     - Captures Web Form Save events, Smart Push invocation timestamps, and user ID.               |
|     - Sample entry:                                                                               |
|       [2026-10-30T10:14:22.105] [Planning] [NOTIFICATION] [HSP-00001] [Form: Revenue_Input]      |
|       Triggering Smart Push 'OEP_FS to OEP_REP' for User: john.doe@acme.com                       |
|                                                                                                   |
|  2. ESSBASE APPLICATION LOG (Vision.OEP_REP.log):                                                 |
|     - Captures low-level C++ load buffer calls, commit times, and slice generation IDs.           |
|     - Sample entry:                                                                               |
|       [Fri Oct 30 10:14:22 2026] Local/Vision/OEP_REP///Info(1300041)                             |
|       Load buffer [1001] created with duplicate aggregation rule [ADD].                           |
|       [Fri Oct 30 10:14:23 2026] Local/Vision/OEP_REP///Info(1300045)                             |
|       Load buffer [1001] committed. New data slice [slice_0042.dat] created (24 records).         |
|                                                                                                   |
|  3. EPM CLOUD JOB CONSOLE (UI / REST API):                                                        |
|     - Displays high-level execution status, duration, row counts, and rejection details.          |
+---------------------------------------------------------------------------------------------------+
```

---

## 3. Slice Limit Emergency Remediation Playbook

If an ASO cube crashes or rejects all writes with `Slice limit reached (256)`:

### Emergency Step 1: Terminate Active Smart Push Form Usage
Notify end users to pause form saves temporarily to prevent further slice instantiation.

### Emergency Step 2: Trigger Headless Slice Compaction via EPM Automate
Open command line or cloud console:
```powershell
epmautomate login admin_user password_file https://epm.oraclecloud.com domain
epmautomate mergeDataSlices "OEP_REP" mergeOption=all withZeroCells=true
```

### Emergency Step 3: Validate Slice Count Reset
Verify in the application log that `slice_0000.dat` is consolidated and all incremental slice files have been deleted.

### Emergency Step 4: Schedule Nightly Automated Compaction
Ensure the maintenance script is embedded in the nightly EPM Automate batch scheduler to prevent recurrence.

