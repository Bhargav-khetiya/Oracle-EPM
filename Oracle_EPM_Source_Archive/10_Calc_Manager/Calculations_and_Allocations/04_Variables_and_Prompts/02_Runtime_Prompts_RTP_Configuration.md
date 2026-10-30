# 02 Runtime Prompts (RTP): Dynamic User Inputs, Member Limits, and Headless Overrides

## 1. Architectural Essence of Runtime Prompts

A **Runtime Prompt (RTP)** is a Calculation Manager variable configured to prompt the end user for input dynamically at the moment a Business Rule is launched. Instead of executing a calculation across a fixed, hardcoded slice of the database, RTPs allow the user to select the specific Department, Scenario, Version, or Markup Percentage they wish to calculate.

```
+---------------------------------------------------------------------------------------------------+
|                                     RUNTIME PROMPT (RTP) LIFECYCLE                                |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  1. USER LAUNCHES BUSINESS RULE (From Form / Action Menu / Smart View)                            |
|                                                                                                   |
|  2. MODAL RUNTIME PROMPT DIALOG RENDERS:                                                          |
|     +-------------------------------------------------------------------------+                   |
|     | RULE: Run_Department_Allocation                                         |                   |
|     |                                                                         |                   |
|     | Select Cost Center: [ E101_Sales_East           ]  <-- Member Selector  |                   |
|     | Enter Inflation %:  [ 5.5%                      ]  <-- Numeric Input    |                   |
|     | Run Full Rollup?    [ (X) Yes   ( ) No          ]  <-- Boolean Input    |                   |
|     |                                                                         |                   |
|     |                   [ LAUNCH ]       [ CANCEL ]                           |                   |
|     +-------------------------------------------------------------------------+                   |
|                                         |                                                         |
|                                         | User clicks [ LAUNCH ]                                  |
|                                         v                                                         |
|  3. CALCULATION COMPILER TOKEN INTERPOLATION:                                                     |
|     Replaces tokens in compiled script:                                                           |
|     - {RTP_CostCenter}  ===> "E101_Sales_East"                                                    |
|     - {RTP_Inflation}   ===> 0.055                                                                |
|                                         |                                                         |
|                                         v                                                         |
|  4. SUBMITS TARGETED ESSBASE CALC SCRIPT TO ENGINE (< 500ms Execution)                            |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. RTP Configuration Parameters

When enabling the **Is Runtime Prompt** checkbox in the Variable Designer:

| Configuration Attribute | Setting Options | Operational Enforcement |
| :--- | :--- | :--- |
| **Prompt Text** | Freeform string | The user-friendly label displayed in the launch modal (e.g., `"Select Cost Center"`). |
| **Default Value** | Outline Member or Constant | Pre-populates the input box to accelerate user workflow. |
| **Is Required** | True / False | If **True**, blocks rule launch until user supplies a valid selection. |
| **Member Limits** | Member query function | **Critical Security Boundary**: Restricts which members the user can view or select (e.g., `@LEVMBRS("Entity", 0)`). |
| **Use Smart List** | Smart List Name | Renders a dropdown driven by a predefined Planning Smart List. |

---

## 3. Member Selector Limits: Restricting User Slices

Without Member Limits, an end-user could accidentally launch a rule against a top-level parent (e.g., `"Total_Geography"`), locking the entire database.

### 3.1 Common Production Member Limits
* **Level 0 Leaf Only**:
  `@LEVMBRS("Entity", 0)` $\rightarrow$ Prevents selecting summary parents.
* **Descendants of a Specific Region**:
  `@DESCENDANTS("EMEA_Region")` $\rightarrow$ Limits user to their geographic jurisdiction.
* **Relative Members**:
  `@RELATIVE("Operating_Expenses", 0)` $\rightarrow$ Enforces leaf operational account selection.

---

## 4. Headless Execution via EPM Automate & REST API

When running batch automation pipelines, Runtime Prompts must be passed headlessly as parameter key-value pairs:

### 4.1 EPM Automate CLI Syntax
```powershell
epmautomate runBusinessRule "Run_Department_Allocation" RTP_CostCenter="E101_Sales_East" RTP_Inflation=0.055
```

### 4.2 REST API JSON Payload
* **Endpoint**: `POST /HyperionPlanning/rest/v3/applications/Vision/jobs`
* **Payload**:
```json
{
    "jobType": "Rules",
    "jobName": "Run_Department_Allocation",
    "parameters": {
        "RTP_CostCenter": "E101_Sales_East",
        "RTP_Inflation": "0.055"
    }
}
```

---

## 5. RTP Best Practices and Anti-Patterns

1. **Avoid Excessive Prompts**: Do not overwhelm end users with 10+ prompts for a simple rule. Default as many variables as possible or infer them from form context using Groovy.
2. **Never Allow Unbounded Scenario/Year Prompts**: Always restrict Scenario and Year RTPs to active, editable forecast slices to prevent accidental corruption of historical actuals.

