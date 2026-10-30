# 08 Emergency Scenario Walkthroughs & Production War Stories

## Ten Real-World Consulting Crisis Scenarios and Exact Step-by-Step Remediation Playbooks

---

## War Story 1: "The Database Exploded from 150MB to 45GB Overnight!"

### The Crisis:
During peak budget season, the client’s IT director escalated an emergency ticket: the production BSO database had swelled from **150 MB to 45 GB** in two hours, exhausting cloud storage quotas and causing night batch calculations to time out.

### Root Cause Analysis:
A junior developer authored a new allocation rule and enabled `SET CREATEBLOCKONEQ ON;`. However, the calculation script omitted the `FIX` statement on the sparse `Entity` (2,000 members) and `Department` (500 members) dimensions! Essbase evaluated all $1,000,000$ potential sparse combinations and instantiated hundreds of thousands of empty 64KB blocks.

### The Emergency Remediation Playbook:
1. **Halt Batch Jobs**: Immediately cancelled the looping calculation job from the Job Console.
2. **Execute Emergency Empty Block Purge**:
   Created an emergency one-line calculation script and executed it against the cube:
   ```sql
   CLEARBLOCK EMPTY;
   ```
   Essbase scanned the index and unlinked all blocks containing only `#MISSING`.
3. **Trigger Dense Restructure**: Performed an Application Database Refresh to defragment the `.pag` files and reclaim physical disk space. Database shrank back to **180 MB** in 12 minutes!
4. **Remediate the Script**: Enforced strict Level 0 boundaries on the allocation rule and turned `SET CREATEBLOCKONEQ OFF;`.

---

## War Story 2: "The 60-Second Web Form Save Freeze"

### The Crisis:
Finance planners complained that every time they changed a single travel expense number on their web form and clicked **Save**, the browser displayed a spinning wheel for **55 to 65 seconds**, making data entry unbearable.

### Root Cause Analysis:
Inspected the Web Form configuration in Form Designer -> **Smart Push** tab. The administrator had attached a Data Map that synced BSO actuals to ASO reporting, but had **LEFT "USE FORM CONTEXT" UNCHECKED**!
* Every single save triggered a **Full Macro-Slice Push** of 1,500,000 cells across all global entities.

### The Emergency Remediation Playbook:
1. Opened the Form Designer -> Smart Push tab.
2. Checked the **"Use Form Context"** checkbox.
3. Clicked **Save Form Layout**.
4. Tested data entry: Save time dropped from **60 seconds to 450 milliseconds**!

---

## War Story 3: "Smart Push Aborts with HTTP 504 on Budget Cutover Day"

### The Crisis:
On the final day of budget submissions, all 80 planners experienced fatal errors on form saves: `Smart Push failed: HTTP 504 Gateway Timeout`.

### Root Cause Analysis:
Inspected the Essbase application log (`OEP_REP.log`). Found the fatal error:
`ASO Error: Maximum number of data slices reached (256)`.
Because 80 planners had been saving forms with Smart Push every few minutes for 5 days without automated slice maintenance, the target ASO cube had accumulated 256 individual `.dat` slice files, hitting the hard Essbase architectural ceiling and refusing all writes!

### The Emergency Remediation Playbook:
1. Opened PowerShell command line and authenticated via EPM Automate:
   ```powershell
   epmautomate login admin_service secure.epw https://epm-cloud.oraclecloud.com domain
   ```
2. Triggered immediate headless slice compaction with zero-cell removal:
   ```powershell
   epmautomate mergeDataSlices "OEP_REP" mergeOption=all withZeroCells=true
   ```
3. In 2 minutes, all 256 slices were merged into a single clean `slice_0000.dat`.
4. Embedded the command into the nightly EPM Automate batch scheduler so the issue could never recur. Form saves resumed instantly.

---

## War Story 4: "The Balance Sheet Does Not Balance ($2M Imbalance on Board Meeting Day)"

### The Crisis:
Four hours before the Board of Directors meeting, the CFO opened the consolidated Balance Sheet dashboard and saw a **\$2.4 million imbalance** between Total Assets and Total Liabilities & Equity!

### Root Cause Analysis:
The finance team had run the P&L calculation rule, generating Net Income of \$2.4M. However, the automated business rule that carries Net Income into **`Retained Earnings Current Year`** on the Balance Sheet had failed due to a missing member lock.

### The Emergency Remediation Playbook:
1. Verified in Calculation Manager that the `Rollup` rule had an aborted job entry in Job Console.
2. Manually launched the balance sheet roll-forward rule:
   ```sql
   FIX("Plan", "FY25", "Working")
     "Retained_Earnings_Current_Year" = "Net_Income"->"Total_P&L";
   ENDFIX
   ```
3. Executed `Rollup` on the `OEP_FS` cube.
4. Refreshed the dashboard: Assets equaled Liabilities & Equity to the penny ($0.00 variance).

---

## War Story 5: "Nightly ERP Pipeline Fails on 5,000 Rejected Records"

### The Crisis:
The 2:00 AM nightly ERP trial balance integration failed completely. 5,000 general ledger rows were rejected with: `Unknown member: CostCenter_4821`.

### Root Cause Analysis:
The corporate ERP accounting team had added 15 new departmental cost centers in SAP General Ledger without notifying the EPM team. The Data Integration import rule could not resolve the unmapped cost center strings.

### The Emergency Remediation Playbook:
1. In **Data Integration -> Member Mapping**, navigated to the `Cost Center` dimension.
2. Added a temporary fallback **"Like" (Wildcard) Mapping Rule**:
   * Source: `*` $\to$ Target: `Unassigned_CostCenter`.
3. Reran the pipeline: Data loaded successfully into staging, and the P&L was populated in time for morning executive reviews.
4. Later that morning, added the 15 new cost centers to the Entity/Department dimension in EPM, refreshed the database, and remapped the specific accounts.

---

## War Story 6: "Workforce Compensation Rule Crashes with Out of Memory"

### The Crisis:
An HR manager launched the `Calculate Compensation` rule, and the entire EPM server process froze, terminating with: `Essbase Out of Memory (1001004)`.

### Root Cause Analysis:
The rule was written as a static calculation across `@DESCENDANTS("Total_Employee")` (8,000 employees) and `@DESCENDANTS("Total_Department")` (400 departments) simultaneously. The memory required to evaluate all employees across all 12 periods exceeded the 4GB calculation cache ceiling.

### The Emergency Remediation Playbook:
1. Re-architected the rule using **Groovy dynamic micro-slicing**:
   ```groovy
   Set<String> editedEmps = [] as Set
   operation.grid.dataCellIterator { it.isEdited() }.each { 
       editedEmps.add(it.getMemberName("Employee")) 
   }
   String empList = editedEmps.collect { '"' + it + '"' }.join(", ")
   String script = """FIX("Plan", "FY25", ${empList}) "Base_Salary" = "Rate" * 2080; ENDFIX"""
   operation.grid.getCube().executeCalcScript(script)
   ```
2. The calculation now evaluates **strictly the 3 or 4 employees modified on the form**.
3. Runtimes dropped from a fatal memory crash to **180 milliseconds**!

---

## War Story 7: "Two Administrators Locked Calculation Manager and Left for the Weekend"

### The Crisis:
On Friday afternoon, an urgent corporate tax rate change needed to be deployed. However, Calculation Manager blocked all edits with: `Object is locked by user: Sarah.Miller@acme.com`. Sarah had left for vacation.

### Root Cause Analysis:
Sarah's browser session had timed out while she had the rule open in Designer mode, leaving an orphaned exclusive lock in the relational repository.

### The Emergency Remediation Playbook:
1. Navigated to **Calculation Manager -> Tools -> Locks**.
2. Located the rule artifact: `Tax_Allocation_Rule`.
3. Clicked the **Unlock** toolbar button (Service Administrator privilege).
4. The lock was cleared immediately, allowing the deployment to proceed.

---

## War Story 8: "ASO Executive Dashboard Shows 200% Overstated Revenue"

### The Crisis:
The VP of Sales opened an executive dashboard and saw global revenue reported as **\$200 million instead of \$100 million**!

### Root Cause Analysis:
Inspected the Data Map: `OEP_FS to OEP_REP`. In the source member selection for Entity, someone had selected `IDescendants("Total_Company")` instead of `ILvl0Descendants("Total_Company")`.
* Both leaf entities (\$100M total) AND stored parent summaries (\$100M total) were pushed into the ASO reporting cube.
* Because ASO dynamically aggregates leaf members at query time, it added the \$100M leaf rollup TO the \$100M stored parent, producing **\$200M (100% inflation)**!

### The Emergency Remediation Playbook:
1. Cleared the ASO target reporting cube using an MDX physical clear.
2. Updated the Data Map source selection to **`ILvl0Descendants("Total_Company")`**.
3. Re-executed the Data Map push.
4. Revenue immediately reported the correct \$100M total.

---

## War Story 9: "Corrupted Outline Restructure After Interrupted Database Refresh"

### The Crisis:
During an application refresh, a network disruption severed the connection to the database. The application was left in an inconsistent state: users could not log in, and forms threw `Outline file (.otl) corrupted`.

### The Emergency Remediation Playbook:
1. Authenticated via EPM Automate:
   ```powershell
   epmautomate login admin_batch password.epw https://epm.oraclecloud.com domain
   ```
2. Restored yesterday's automated maintenance snapshot:
   ```powershell
   epmautomate importSnapshot "Artifact Snapshot"
   ```
3. Triggered a clean application refresh:
   ```powershell
   epmautomate refreshCube
   ```
4. The entire application, database outlines, and relational schemas were completely restored and validated in **14 minutes**.

---

## War Story 10: "Smart View Sheet Returns '#No Access' for Regional Controller"

### The Crisis:
The EMEA Regional Controller opened a budget submission sheet in Excel Smart View and all cells displayed `#No Access`, even though their security group had "Write" access to `EMEA_Entity`.

### Root Cause Analysis:
Inspected **Cell-Level Security (CLS)** and **Valid Intersections**. 
* The user had Write access to `EMEA_Entity`, but an active Cell-Level Security policy had declared `Version: Working` as **Read-Only** for all users until the formal budget submission date!
* Cell-Level Security overrode dimension-level permissions.

### The Emergency Remediation Playbook:
1. Navigated to **Tools -> Access Permissions -> Cell-Level Security**.
2. Adjusted the effective date on the CLS rule to allow budget entry.
3. Controller clicked **Refresh** in Smart View: all cells unlocked for data input immediately.

