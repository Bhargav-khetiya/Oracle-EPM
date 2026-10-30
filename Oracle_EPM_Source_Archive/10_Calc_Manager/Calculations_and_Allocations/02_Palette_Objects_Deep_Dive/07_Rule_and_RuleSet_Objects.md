# 07 Rule and Rule Set Components: Orchestration, Variable Merging, and Parallelism

## 1. Modular Architecture: Rules vs. Rule Sets

Enterprise financial workflows rarely consist of a single standalone calculation. A complete financial close or forecast cycle involves clearing prior targets, calculating operational drivers, computing allocations, aggregating departmental hierarchies, and translating currencies.

Calculation Manager supports modular composition through two high-level orchestration artifacts:
1. **Rule Component**: An existing business rule embedded as a sub-routine node within another rule flowchart.
2. **Rule Set**: A parent container that sequences multiple independent business rules into a single executable pipeline.

```
+---------------------------------------------------------------------------------------------------+
|                                      RULE SET PIPELINE ANATOMY                                    |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  RULE SET: [Monthly_Financial_Forecast_Close]                                                     |
|  Configuration: Stop On Error = TRUE | Execution Mode = SERIAL                                    |
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | STEP 1: Rule [01_Clear_Forecast_Target_Slice]                                               |  |
|  | Slices: Scenario: Forecast, Years: FY25, Versions: Working                                  |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|                                                  v (Exit Code 0: Success)                         |
|  +---------------------------------------------------------------------------------------------+  |
|  | STEP 2: Rule [02_Calculate_Revenue_and_COGS]                                                |  |
|  | Bottom-Up execution of pricing drivers across all Level 0 Products                         |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|                                                  v (Exit Code 0: Success)                         |
|  +---------------------------------------------------------------------------------------------+  |
|  | STEP 3: Rule [03_Allocate_Corporate_Overhead]                                              |  |
|  | Multi-tier cascade from Corporate Pool to Department Targets                               |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|                                                  v (Exit Code 0: Success)                         |
|  +---------------------------------------------------------------------------------------------+  |
|  | STEP 4: Rule [04_Aggregate_Financial_Dimensions]                                            |  |
|  | Full CALC DIM on Sparse Entity, Department, and Project hierarchies                          |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|                                                  v                                                |
|  [RULE SET EXECUTION COMPLETE]                                                                    |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Rule Set Properties & Configuration

When designing a Rule Set in Calculation Manager:

| Configuration Property | Options | Operational Impact |
| :--- | :--- | :--- |
| **Stop On Error** | Checked / Unchecked | If **Checked**, any failure in an earlier rule (e.g., divide by zero error or missing member) immediately aborts the entire Rule Set, preventing corrupt downstream calculations. |
| **Execution Order** | Ordered List | Defines the exact chronological sequence in which rules execute. |
| **Keep Variable Values** | Checked / Unchecked | Persists evaluated variable values from Rule 1 so they can be consumed by Rule 2 without re-prompting. |
| **Parallel Execution** | Supported in specific EPM Cloud / Essbase environments | Executes independent rules across separate CPU calculation threads simultaneously. |

---

## 3. Runtime Prompt (RTP) Aggregation & Variable Merging

One of the greatest usability advantages of a Rule Set is **Variable Deduplication**:

### The Problem Without Variable Merging:
If a Rule Set contains 4 rules, and each rule has a Runtime Prompt for `{RTP_Scenario}` and `{RTP_Year}`, an end user triggering the Rule Set would be prompted 4 consecutive times for the identical scenario and year!

### The Calculation Manager Resolution:
1. When a Rule Set is validated, Calculation Manager scans all member rules for Runtime Prompts.
2. If multiple rules reference a variable with the **exact same name and data type** (e.g., `{RTP_Year}`):
   * The compiler merges them into a **single consolidated prompt dialog**.
   * The end user selects the year once upon launch.
   * That value is injected into all 4 rules across the pipeline simultaneously.

---

## 4. Deployment and Application Association

* **Independent Deployment**: Rule Sets must be deployed explicitly. Deploying individual rules does NOT automatically deploy the parent Rule Set.
* **Form Association**: Rule Sets can be attached to Web Data Forms under the **Business Rules** tab:
  * **Run Before Load**: Executes before grid data is fetched.
  * **Run After Save**: Executes immediately after the user commits form edits.
* **EPM Automate Execution**:
  ```powershell
  epmautomate runBusinessRule "Monthly_Financial_Forecast_Close" RTP_Scenario=Forecast RTP_Year=FY25
  ```

