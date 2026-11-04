# 03 — Business Rules & Smart Push on Forms: Automation Architecture

---

## 3.1 Overview: Automated Calculations & Cross-Cube Sync

In Oracle EPM Planning, data forms are not merely passive spreadsheets. Through the **Business Rules** and **Smart Push** tabs, forms act as active automation pipelines that calculate financial logic and synchronize reporting cubes in real time upon save.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FORM AUTOMATION LIFECYCLE                       │
├────────────────────────────────────────────────────────────────────────┤
│ 1. USER CLICKS OPEN FORM                                               │
│    └── [Run Before Load]: Pre-seeds data / runs initial preparation    │
│    └── Form retrieves data from Essbase .PAG blocks                    │
│    └── [Run After Load]: Prepares dynamic drivers in memory            │
│                                                                        │
│ 2. USER ENTERS DATA & CLICKS SAVE                                      │
│    └── [Run Before Save]: Validates cell inputs & business logic       │
│    └── Essbase commits dirty data blocks to disk (.PAG)                │
│    └── [Run After Save]: Executes aggregation (e.g. FinPlan_01_Agg)    │
│    └── [Smart Push Executes]: Pushes updated data FinPlan -> EPBCS     │
│        (Runs in background via async thread)                           │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3.2 Business Rules on Forms: The 4 Execution Hooks

From your supplied production extraction (`forms property.txt`):

```
┌─────────────────────────────────────────────────────────────┐
│                    BUSINESS RULES PROPERTIES                │
├─────────────────────────────────────────────────────────────┤
│ Selected Business Rules:                                    │
│   • <Calculate Currencies>                                  │
│   • <Calculate Form>                                        │
│   • FinPlan_01_Aggregation                                  │
│                                                             │
│ Execution Hooks:                                            │
│   [ ] Run Before Load       [X] Run Before Save             │
│   [ ] Run After Load        [X] Run After Save              │
│                                                             │
│ Options:                                                    │
│   [X] Use Members on Form                                   │
│   [X] Hide Prompt                                           │
└─────────────────────────────────────────────────────────────┘
```

### The 4 Execution Hooks Explained:
1. **`Run Before Load`**:
   * Executes **before** the form queries Essbase.
   * *Best Use Case*: Copying prior-period actuals into a rolling forecast before the user views the grid.
2. **`Run After Load`**:
   * Executes immediately after the form data is loaded into application memory, before rendering in the browser.
3. **`Run Before Save`**:
   * Executes **after** the user clicks Save, but **before** the dirty blocks are committed to the Essbase `.PAG` files.
   * *Best Use Case*: Running pre-save validation rules. If a condition fails (e.g., total allocation does not equal 100%), the rule throws an `@RETURN` error, canceling the save.
4. **`Run After Save`**:
   * Executes immediately **after** the modified cells are safely committed to disk.
   * *Best Use Case*: Departmental aggregation (`FinPlan_01_Aggregation`), P&L calculations (`Aggregate_Income_Expense`), or catering revenue calculations.

### Critical Rule Options:
* **`Use Members on Form`**: Injects the active form's Page, POV, and row coordinates directly into the rule's Runtime Prompts (RTPs). This ensures the rule runs **only for the current department and scenario**, preventing full-cube calculation bottlenecks.
* **`Hide Prompt`**: Suppresses prompt pop-ups when form context satisfies all RTP variables.

---

## 3.3 Smart Push on Forms: Real-Time Cross-Cube Synchronization

From your supplied extraction:

```
┌─────────────────────────────────────────────────────────────┐
│                      SMART PUSH PANEL                       │
├─────────────────────────────────────────────────────────────┤
│ [X] Run Smart Push In Background                            │
│ [X] Use Database Suppression                                │
│                                                             │
│ Data Map:           [FinPlan_to_EPBCS_Reporting            ]│
│ Use Form Context:   [X] Checked                             │
│ Overwrite Selection:[ ] Unchecked                           │
│ Run After Save:     [X] Checked                             │
└─────────────────────────────────────────────────────────────┘
```

### What is Smart Push—
In enterprise applications, data is entered in a detailed Block Storage (BSO) cube (`FinPlan`), but executive reports are queried from an Aggregate Storage (ASO) cube (`EPBCS`).
* **Smart Push** automatically extracts the saved data slice from `FinPlan` and loads it into `EPBCS` the moment the user clicks **Save**.
* **`Run Smart Push In Background`**: Executes the data transfer asynchronously on a background server thread. The planner receives instant confirmation ("Data Saved") and continues working without waiting for the reporting cube refresh to finish.
* **`Use Form Context`**: Restricts the data transfer slice strictly to the members present on the active form, moving only 50 cells instead of the entire database.
