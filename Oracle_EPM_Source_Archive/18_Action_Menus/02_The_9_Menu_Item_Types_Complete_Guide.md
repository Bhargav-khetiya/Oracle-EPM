# 02 — The 9 Menu Item Types: Complete Reference

---

## 2.1 Overview of Menu Item Types

The **Type** dropdown determines the operational capability of the right-click menu item. The Planning kernel supports exactly 9 distinct types:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        THE 9 MENU ITEM TYPES                           │
├────────────────────┬───────────────────────────────────────────────────┤
│ 1. URL             │ Launches external websites, BI dashboards, or ERP │
│ 2. Form            │ Contextual navigation to another Planning form    │
│ 3. Business Rule   │ Triggers Essbase calculation scripts or Groovy    │
│ 4. Manage Approvals│ Opens the Planning Unit approval workflow screen  │
│ 5. Dashboard       │ Opens a composite Planning 2.0 dashboard          │
│ 6. Change Status   │ Executes promotional approval actions directly    │
│ 7. Menu Header     │ Visual grouping folder or separator bar           │
│ 8. Previous Form   │ Dynamic breadcrumb return to previous form        │
│ 9. Copy Version    │ Copies data from one version to another           │
└────────────────────┴───────────────────────────────────────────────────┘
```

---

## 2.2 Type 1: URL

```
┌─────────────────────────────────────────────────────────────┐
│                          URL PANEL                          │
├─────────────────────────────────────────────────────────────┤
│ URL:                [https://erp.orbrick.com/ledger?cc=$Row$]│
│ Use Form Context:   [X] Checked                             │
└─────────────────────────────────────────────────────────────┘
```

* **Purpose**: Allows planners to seamlessly drill out from an EPM data cell into an external system (e.g., Oracle ERP General Ledger, Workday HCM, Salesforce CRM, or Power BI).
* **Fields**:
  * **`URL`** *(Required)*: The target web address.
  * **`Use Form Context`** *(Checkbox)*: When checked, Planning appends the active cell's dimension coordinates as HTTP query parameters to the URL string.
* **Context Token Syntax**:
  * Standard URL parameters: `https://mybi.com/report?entity=$Entity$&period=$Period$&account=$Account$`
  * Planning replaces `$Entity$`, `$Period$`, `$Account$` at runtime with the exact names of the clicked members.

---

## 2.3 Type 2: Form

* **Purpose**: Contextual cross-form navigation. Allows users to click on a summary line item (e.g., Total Travel Expense) and immediately jump to a detailed line-item input form.
* **Fields**:
  * **`Form`** *(Required)*: The target form name selected via the **Add Form** picker control.
* **Context Passing**: If the source form is open for `Entity: E10002` and `Scenario: Budget`, the target form automatically opens with its POV set to `E10002` and `Budget`.

---

## 2.4 Type 3: Business Rule

The most versatile and frequently used menu type in Oracle EPM. Allows users to execute calculations on demand directly from the grid.

```
┌─────────────────────────────────────────────────────────────┐
│                     BUSINESS RULE PANEL                     │
├─────────────────────────────────────────────────────────────┤
│ Cube:                      [FinPlan                       ▼]│
│ Business Rules:            [Catering Revenue calculation  ▼]│
│ View Type:                 [Classic View                  ▼]│
│ Window Title:              [Calculate Catering Revenue     ]│
│ OK Button Label:           [Calculate Now                  ]│
│ Cancel Button Label:       [Cancel                         ]│
│ Launch Confirmation Msg:   [Calculation launched for $Row$ ]│
│ Launch in separate window: [ ] Unchecked                    │
│ Hide Prompt:               [X] Checked                      │
└─────────────────────────────────────────────────────────────┘
```

### Detailed Field Breakdown:
1. **`Cube`**: Dropdown showing application plan types (`FinPlan`, `EPBCS`, `Manpower`, `Capital`).
2. **`Business Rules`** *(Required)*: Dropdown listing all deployed rules in the selected cube. In your extraction, 52 production rules are listed, including:
   * `Aggeregate_Income_Expense`
   * `Clear_FY26_Actual_P&L`
   * `Catering Revenue calculation`
   * `BR_Task_10_TrendBased_Planning_with_Smart_Sheet`
   * `FY26_Actual_Copy_data_to_Budget_on_E10002`
3. **`View Type`**:
   * **`Classic View`**: Renders standard ADF pop-up window with runtime prompt selectors.
   * **`Streamline View`**: Renders a sleek, modern inline modal with compact controls.
4. **`Hide Prompt`**: When checked, if all required Runtime Prompts (RTPs) can be satisfied by the clicked cell context, **Planning executes the rule immediately without displaying a prompt dialog to the user**.

---

## 2.5 Type 4: Manage Approvals (Workflow)

```
┌─────────────────────────────────────────────────────────────┐
│                      WORKFLOW PANEL                         │
├─────────────────────────────────────────────────────────────┤
│ Scenario:  [Budget                                        ▼]│
│ Version:   [Working                                       ▼]│
└─────────────────────────────────────────────────────────────┘
```

* **Purpose**: Navigates the user directly to the Planning Unit Hierarchy (PUH) management screen for the specific Scenario and Version configured.
* **Available Options in Extract**:
  * **Scenarios (14 named)**: `Act vs Bud`, `Actual`, `Budget`, `Budget vs Actual`, `Current`, `CY_vs_NY`, `CYActual vs NYActual`, `Forecast`, `No Scenerio`, `Plan`, `PY_vs_CY`, `PYActual vs CYActual`, `Variance`, `Variance Comments`.
  * **Versions (5 named)**: `BU Version_1`, `Final`, `Sandboxes`, `What if`, `Working`.

---

## 2.6 Type 5: Dashboard

* **Purpose**: Opens a Planning 2.0 interactive dashboard dynamically filtered to the active row and column context.
* **Field**: **`Dashboard`** *(Required)*: Selected via the dashboard picker control.

---

## 2.7 Type 6: Change Status (Approval Promotion Actions)

Allows planners and managers to promote, approve, or reject budgets directly by right-clicking a cell without opening the approval dashboard.

```
┌─────────────────────────────────────────────────────────────┐
│                    CHANGE STATUS PANEL                      │
├─────────────────────────────────────────────────────────────┤
│ Filter Actions by Template: [Bottom Up                    ▼]│
│ Action:                     [Promote                      ▼]│
│ Approval Status:            [X] Checked                     │
│ Hide Prompt:                [ ] Unchecked                   │
│ Show Annotation History:    [X] Checked                     │
└─────────────────────────────────────────────────────────────┘
```

### The 20 Supported Approval Actions:
1. **`Start`**: Initiates the approval workflow for an entity.
2. **`Exclude`**: Excludes the entity from the current cycle.
3. **`Promote`**: Moves budget forward to the next reviewer in the hierarchy.
4. **`Sign Off`**: Final executive endorsement.
5. **`Reject`**: Sends budget back to previous owner with comments.
6. **`Approve`**: Grants managerial approval.
7. **`Delegate`**: Reassigns approval authority to a peer.
8. **`Take Ownership`**: Administrator/Manager seizes write lock.
9. **`Originate`**: Creates an ad-hoc approval unit.
10. **`Freeze` / `Unfreeze`**: Temporarily locks/unlocks data blocks.
11. **`Distribute` / `Distribute Children` / `Distribute Owner`**: Cascades target allocations down through the hierarchy.
12. **`Need Assistance`**: Requests executive assistance during budget cycle.
13. **`Return`**: Reverts unit to original preparer.
14. **`Submit` / `Submit to Top`**: Bypasses intermediate reviewers and submits directly to top-level CFO.
15. **`Reopen`**: Re-activates an approved, signed-off budget.
16. **`Pass`**: Passes unit to next reviewer without comment.

---

## 2.8 Type 7: Menu Header

* **Purpose**: Creates sub-menu categories or visual dividers.
* **Separators**: To create a visual horizontal separator bar, create a Menu Header and set its **Label to a single hyphen (`-`)**.

---

## 2.9 Type 8: Previous Form

* **Purpose**: Breadcrumb navigation. Dynamically returns the planner to the exact form they came from, preserving their scroll position and POV.

---

## 2.10 Type 9: Copy Version

* **Purpose**: Allows planners to copy an entire version slice into another version on demand.
* **Fields**:
  * **`Scenario`** *(Required)*: Filter scenario.
  * **`Copy From`** *(Required)*: Source version (`Base`, `BU Version_1`, `Direct Input`, `Final`, `Sandboxes`, `What if`, `Working`).
  * **`Copy To`** *(Required)*: Target version.
