# 03 Data Maps Administration, Validation Engine, and Scheduled Jobs

## 1. Web UI Workflow and Configuration Architecture

Data Maps are managed centrally through the Oracle EPM Cloud Web UI under **Application -> Data Exchange -> Data Maps** (or **Tools -> Data Maps** depending on the application theme). The configuration interface abstracts underlying MDX and C++ Essbase buffer API calls into a declarative mapping canvas.

```
+---------------------------------------------------------------------------------------------------+
|                                   DATA MAP CONFIGURATION INTERFACE                                |
+---------------------------------------------------------------------------------------------------+
| Data Map Name: [OEP_FS to OEP_REP                      ]   Status: [Active    ]                   |
| Source Cube:   [OEP_FS (BSO)                           ]   Target: [OEP_REP (ASO)                 ]   |
+---------------------------------------------------------------------------------------------------+
| OPTIONS:                                                                                          |
|   [X] Clear Target Data Before Push    [ ] Copy Comments    [ ] Copy Attachments                  |
|   [X] Aggregate Data on Target Cube    [X] Submit as Background Job                               |
+---------------------------------------------------------------------------------------------------+
| DIMENSION MAPPINGS:                                                                               |
| Source Dimension   Target Dimension   Source Selection                Target Selection            |
| -----------------  -----------------  ------------------------------  --------------------------- |
| Account            Account            ILvl0Descendants(Total_Income)  (Exact Match)               |
| Entity             Entity             ILvl0Descendants(Total_Entity)  (Exact Match)               |
| Period             Period             Jan:Dec                         (Exact Match)               |
| Years              Years              FY24, FY25, FY26                (Exact Match)               |
| Scenario           Scenario           "Plan", "Forecast"              (Exact Match)               |
| Version            Version            "Working"                       "Final"                     |
| Plan_Element       (Unmapped Source)  "Total_Plan_Element"            N/A (Filtered at Source)    |
| (Unmapped Target)  View               N/A                             "Periodic"                  |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Validation Engine Mechanics

Before any Data Map can be executed or associated with a web form as a Smart Push, it must pass the **Planning Metadata Validation Engine**. 

### 2.1 What the Validation Engine Checks
1. **Dimensional Validity**: Ensures that every dimension in the target cube is accounted for—either through an active source mapping or an explicit fixed member assignment.
2. **Member Existence**: Verifies that all explicit member names and function roots (e.g., `Total_Income`) exist in the current application outline.
3. **Data Storage Integrity**:
   * Evaluates target coordinates to confirm no targets are tagged as **Dynamic Calc**, **Label Only**, or **Store Data = No**.
   * Pushing data to a dynamic target produces a fatal runtime error: `Essbase Error (1200497): Error executing data load. Target member is calculated.`
4. **Data Type Compatibility**: Validates that source currency/numeric metrics do not target text or date fields unless explicit type translation rules are declared.
5. **ASO Dimension Storage**: Verifies that ASO target dimensions with Multiple Hierarchies have valid level 0 target intersections.

### 2.2 Validation Triggers and Statuses
* **Auto-Validation on Save**: The UI automatically compiles the mapping definitions into internal relational descriptors upon saving.
* **Metadata Refresh Warning**: When an application database refresh occurs, Data Maps containing renamed, deleted, or moved members are flagged with a red exclamation point `[!] Invalid` in the Data Maps catalog.
* **Silent Failures Prevention**: If a member selection query returns an empty set (e.g., `ILvl0Descendants(Temporary_Project)` where no children exist), the validation engine issues a warning that 0 cells will be moved.

---

## 3. Execution Topologies and Interfaces

Oracle EPM Cloud supports five distinct operational modes for executing Data Maps:

```
+---------------------------------------------------------------------------------------------------+
|                                     DATA MAP EXECUTION MODES                                      |
+---------------------------------------------------------------------------------------------------+
| 1. On-Demand Web UI Push      | Admin clicks "Actions" -> "Push Data" on selected map.            |
| 2. Smart Push on Form Save    | Automatic real-time micro-slice push upon end-user form submit.   |
| 3. Scheduled Job Console     | Automate via EPM Job Scheduler (hourly, nightly batch).           |
| 4. EPM Automate Command Line  | Headless CLI script orchestration via 'epmautomate runDataMap'.   |
| 5. REST API Endpoints         | External enterprise ETL / Postman / Python JSON payload requests. |
+---------------------------------------------------------------------------------------------------+
```

---

## 4. EPM Automate Orchestration

Enterprise automation pipelines routinely execute Data Maps using `epmautomate`. This is critical for nightly batch windows where operational BSO cubes must push consolidated totals into reporting ASO cubes.

### 4.1 CLI Syntax
```powershell
epmautomate runDataMap "OEP_FS to OEP_REP" [clearTargetData=true|false]
```

### 4.2 Production PowerShell Batch Script with Error Handling
```powershell
<#
==================================================================================
Script: Execute_EPM_DataMap_Batch.ps1
Purpose: Headless execution of Data Map with session management & status polling
==================================================================================
#>

$url      = "https://epm-test-cloud.oraclecloud.com/HyperionPlanning"
$domain   = "epm_domain"
$user     = "admin_service_account"
$password = "C:\EPM_Automate\secure_pwd.epw"
$mapName  = "OEP_FS to OEP_REP"

# 1. Login to EPM Cloud instance
Write-Host "Connecting to Oracle EPM Cloud..."
epmautomate login $user $password $url $domain

if ($LASTEXITCODE -ne 0) {
    Write-Error "EPM Automate Login Failed with exit code $LASTEXITCODE"
    exit 1
}

# 2. Execute Data Map with Target Clear
Write-Host "Triggering Data Map: $mapName..."
epmautomate runDataMap $mapName clearTargetData=true

if ($LASTEXITCODE -ne 0) {
    Write-Error "Data Map Execution Failed! Check EPM Job Console."
    epmautomate logout
    exit 2
}

Write-Host "Data Map completed successfully."

# 3. Terminate Session
epmautomate logout
Write-Host "Session terminated safely."
```

---

## 5. REST API Execution and Job Polling

External integration platforms (e.g., Workato, MuleSoft, Azure Data Factory, Python ETL) trigger Data Maps via the Oracle EPM Cloud Planning REST API.

### 5.1 POST Request: Initiate Data Map Job
* **URL**: `https://<epm_instance>/HyperionPlanning/rest/v3/applications/<AppName>/jobs`
* **Method**: `POST`
* **Headers**:
  * `Content-Type: application/json`
  * `Authorization: Basic <Base64_Encoded_Credentials>`
* **Payload**:
```json
{
    "jobType": "Push Data",
    "jobName": "OEP_FS to OEP_REP",
    "parameters": {
        "clearTargetData": "true"
    }
}
```

### 5.2 Response Payload (Job Initiation)
```json
{
    "jobId": 481029,
    "jobName": "OEP_FS to OEP_REP",
    "jobType": "Push Data",
    "status": -1,
    "descriptiveStatus": "In Progress",
    "links": [
        {
            "rel": "self",
            "href": "https://<epm_instance>/HyperionPlanning/rest/v3/applications/Vision/jobs/481029"
        }
    ]
}
```

### 5.3 Polling Job Status
The client application queries the `href` link returned in the initiation response until `status` transitions:
* `status = -1`: In Progress
* `status = 0`: Success (Data moved and committed)
* `status = 1`: Completed with Warnings
* `status = 2`: Failed (Inspect `details` array in JSON response)

---

## 6. Target Data Clearing Architecture: Physical vs. Logical Clear

When the **Clear Target Data** option is enabled, Data Maps must scrub old target intersections before writing new data to prevent obsolete or orphaned numbers from persisting.

### 6.1 BSO Target: Physical Block Clearing
* Generates an internal MDX specification matching the target intersection slice.
* Executes a low-level Essbase `CLEARBLOCK` operation:
  * If the entire sparse block is included in the clear slice, Essbase marks the block header as free and unlinks it from the index file (`app.ind`).
  * If only partial cells within a dense block are targeted, Essbase writes `#MISSING` across the dense coordinates.

### 6.2 ASO Target: Slice Clearing Mechanisms
ASO does not modify existing data blocks in place. When Clear Target Data is invoked on an ASO target:
1. **Logical Clear (Compensation Slice)**:
   * EPM Cloud extracts the current values residing in the target slice and generates an inverted sign compensation slice.
   * Loading $+100$ and then loading $-100$ produces a net aggregate sum of $0$.
2. **Physical Slice Clear (MDX Clear)**:
   * For partition-aligned slices, Essbase executes an MDX partial data clear:
     ```sql
     alter database [App].[OEP_REP] clear data in_region 
     'CrossJoin({[FY24]}, CrossJoin({[Working]}, Descendants([Total_Income])))' 
     physical;
     ```
   * Physical clearing reclaims disk space immediately by slicing the underlying `default.dat` storage buffers.

