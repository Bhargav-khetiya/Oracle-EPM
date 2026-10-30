# 05 — Action Menus: Troubleshooting, Security, & Interview Bible

> **Source Reference**: Extracted from production planning extractions (`action menu.txt`) and enterprise implementation standards.

---

## 5.1 Production Troubleshooting Matrix

| Symptom / Defect | Root Cause | Diagnostic Step | Resolution Step |
| :--- | :--- | :--- | :--- |
| **Menu item does not appear on right-click** | `Required Parameters` filter does not match clicked cell. | Verify if clicked cell is a data cell or header. Check Required Parameters setting. | Set Required Parameters to `None` for testing, or set to match exact target zone. |
| **Action Menu missing in Smart View** | Action menu not assigned to the form, or user right-clicked on Excel POV cell. | Verify form properties in Web. Confirm user is right-clicking within grid data cells. | Assign Action Menu under Form Properties $\rightarrow$ Context Menus. Advise user to click in grid. |
| **Prompt dialog still pops up with "Hide Prompt" checked** | A required Runtime Prompt cannot be derived from grid coordinates. | Review Business Rule RTP definitions. Check which prompt is missing default value. | Assign default member or ensure missing dimension exists in Form Page/POV. |
| **Target Form opens with empty grid ("No Data")** | User selected an intersection that has no valid data or violates Valid Intersections. | Check POV of target form. Verify user security and valid intersection rules. | Check target form layout and enable "Suppress Missing Blocks" or review filters. |
| **Calculation executes on the wrong Entity** | Rule RTP variable name does not match the dimension name expected by Context Relay. | Inspect Calc Manager variable naming (e.g. `{Entity_RTP}`). | Rename RTP variable to standard dimension name or configure explicit prompt mapping. |
| **Copy Version accidentally overwrote entire Budget** | Menu item was launched without restricting POV, wiping target version. | Check Copy Version configuration. Review audit logs for target slice. | Restrict Copy Version via Form Context or use Groovy/Data Maps with explicit FIX statements. |
| **Change Status action button grayed out / disabled** | Selected action is not valid for the approval unit's current state or template. | Check Planning Unit status and template (Bottom Up vs Free Form). | Verify user ownership and approval unit state before invoking action. |

---

## 5.2 Security and Governance Model

Action Menu execution is governed by a three-tiered security architecture:

```
[TIER 1: FORM-LEVEL ATTACHMENT]
  └── The Action Menu must be assigned to the Web Data Form
      (Form Properties -> Context Menus -> Selected Menus).

[TIER 2: TARGET ARTIFACT SECURITY]
  ├── Target Business Rule: User must have "Launch" role access.
  ├── Target Form: User must have "Read" or "Write" access.
  └── Target Dashboard: User must have view permissions.
  * If a user lacks permission to the target rule, the menu item
    is automatically HIDDEN from that user's right-click menu.

[TIER 3: DATA CELL SECURITY & CELL-LEVEL ACCESS]
  └── Even if a rule launches, Essbase enforces write security on
      the targeted data blocks.
```

---

## 5.3 Safe Testing Plan for Copy Version

Because **Copy Version** can overwrite large volumes of data across all entities and accounts, consultants must follow a strict testing protocol:

1. **Create an Isolated Test Version**: Never test against `Final` or `Working`. Create a dedicated sandbox version named `Test_Copy`.
2. **Limit Scenario Scope**: Bind the menu item to a test scenario (e.g., `What if`) before pointing to `Budget` or `Actual`.
3. **Verify Overwrite vs. Merge**: Confirm whether the copy operation clears existing data in the target version before copying, or performs an additive merge.
4. **Audit Data Pre- and Post-Copy**: Run an ad-hoc Smart View grid on `Test_Copy` before and after invoking the menu item to verify data integrity.

---

## 5.4 Golden Do's and Don'ts of Action Menus

### ✅ The DO's:
1. **DO use `Hide Prompt` with Context Relay** to provide a seamless, 1-click user calculation experience.
2. **DO use Separator Bars (`-`)** to organize long menus into logical sections (Navigation, Calculations, Approvals).
3. **DO scope business rules using `Required Parameters`** (e.g., target `Department: D10010` for catering rules) to prevent users from running rules on irrelevant data.
4. **DO test Action Menus in Smart View** to confirm Excel flyout compatibility before deploying to finance teams.
5. **DO create breadcrumb return paths using `Previous Form`** so planners can navigate back without losing their workflow context.

### ❌ The DON'Ts:
1. **DON'T leave all menu items set to `Required Parameters: None`**; it creates cluttered 20-item right-click menus that overwhelm end users.
2. **DON'T include spaces or punctuation in the `Menu Item` name**; use underscores (`_`) only.
3. **DON'T launch full-database calculations (`CALC ALL`) from an Action Menu**; scope calculations strictly to the clicked cell's entity or department.
4. **DON'T assume Smart View supports right-clicking on POV dropdown cells**; train users to right-click inside the spreadsheet data grid.

---

## 5.5 20 Consultant Interview Questions & Answers

### Beginner Level (Fundamentals)

#### Q1: What is an Action Menu in Oracle EPM Cloud Planning?
> **Answer**: An Action Menu is a customizable right-click contextual context menu that can be associated with data forms, composite dashboards, and Smart View ad-hoc grids. It allows users to execute business rules, navigate to other forms/dashboards, open external URLs, manage approvals, or copy versions directly from an active data cell.

#### Q2: What are the 9 supported Menu Item types in Oracle EPM Planning?
> **Answer**:
> 1. `URL`
> 2. `Form`
> 3. `Business Rule`
> 4. `Manage Approvals`
> 5. `Dashboard`
> 6. `Change Status`
> 7. `Menu Header`
> 8. `Previous Form`
> 9. `Copy Version`

#### Q3: How do you create a visual horizontal separator line inside an Action Menu?
> **Answer**: Create a new menu item with Type = **`Menu Header`**, and set its **Label to a single hyphen (`-`)**. Planning automatically renders this as a clean horizontal divider bar.

#### Q4: How is an Action Menu attached to a web data form?
> **Answer**: In the Form Designer, navigate to the **Properties** tab $\rightarrow$ **Context Menus** section. Select the desired menu from **Available Menus** and move it to **Selected Menus**, then save the form.

#### Q5: What is the maximum character limit for the `Menu Item` name and `Label` fields?
> **Answer**: Both fields enforce a maximum limit of **80 characters**. The Menu Item name serves as the internal programmatic identifier, while Label is the display string visible to end users.

---

### Intermediate Level (Targeting & Context Passing)

#### Q6: What is Context Relay in Oracle EPM Action Menus?
> **Answer**: Context Relay is the mechanism where Planning captures the exact Page, POV, Row, and Column dimensional coordinates of the cell a user right-clicked, and automatically injects those members into the target object (e.g., passing them to a target form's POV, a business rule's Runtime Prompts, or URL query parameters).

#### Q7: What are the 23 available options in the `Required Parameters` dropdown?
> **Answer**:
> - **Universal (1)**: `None`
> - **Application Dimensions (16)**: `Account`, `AssetClass`, `AssetDetail`, `Currency`, `Custom1`, `Department`, `Employee`, `Entity`, `Future`, `Grade`, `HSP_View`, `Period`, `PlanElement`, `Scenario`, `Version`, `Years`
> - **Grid Axes (4)**: `Point of View`, `Page`, `Row`, `Column`
> - **Targeting Modes (2)**: `Members only`, `Cell Only`

#### Q8: What is the difference between `Members only` and `Cell Only` in Required Parameters?
> **Answer**: `Members only` restricts the menu item to appear only when right-clicking text member headers (row or column headers). `Cell Only` ensures the item appears only when right-clicking numerical data cells (editable or read-only values).

#### Q9: What happens when `Use Form Context` is checked on a URL menu item?
> **Answer**: Planning appends the current cell's dimensional coordinates as HTTP GET parameters (or replaces configured `$Dimension$` tokens) in the target URL string, allowing seamless drill-out into ERP ledgers or external BI tools.

#### Q10: What is the difference between `Classic View` and `Streamline View` when configuring a Business Rule menu item?
> **Answer**: `Classic View` opens the traditional ADF dialog window displaying standard prompt controls. `Streamline View` renders a modern, lightweight inline popup dialog designed for rapid user interaction.

---

### Advanced Level (Calculations, Workflow & Copying)

#### Q11: What happens if `Hide Prompt` is checked on a Business Rule menu item, but a required Runtime Prompt is missing from the form context?
> **Answer**: Planning's failsafe engine overrides the `Hide Prompt` setting and automatically presents the prompt dialog to the user, ensuring the calculation does not fail or execute with uninitialized variables.

#### Q12: How does the `Previous Form` menu item determine which form to return to?
> **Answer**: Planning maintains an in-memory session navigation stack for the user. When `Previous Form` is invoked, it pops the top form from the stack, redirecting the user to the previous form while preserving its exact Page, POV, and scroll state.

#### Q13: What are the 4 templates available in `Filter Actions by Template` under the Change Status panel?
> **Answer**: **`All`**, **`Bottom Up`**, **`Distribute`**, and **`Free Form`**. These filter the list of allowable approval actions to match the governance model configured for the planning unit.

#### Q14: Name 5 approval actions available in the `Change Status` panel and their functions.
> **Answer**:
> 1. `Promote`: Advances the budget to the next reviewer in the approval hierarchy.
> 2. `Reject`: Returns the budget to the previous owner with mandatory annotations.
> 3. `Approve`: Finalizes and locks the planning unit at the managerial level.
> 4. `Freeze`: Temporarily locks data entry without promoting the unit.
> 5. `Take Ownership`: Allows an administrator or higher-level manager to seize write access.

#### Q15: What is the architectural risk of deploying a `Copy Version` menu item with `Required Parameters: None`?
> **Answer**: Planners might accidentally right-click anywhere and execute a broad, multi-entity copy operation, inadvertently overwriting entire budgets across un-reviewed departments. Copy Version items should always be restricted by dimension or form context.

---

### Scenario-Based & Production Debugging

#### Q16: A user right-clicks on cell `C10` in Smart View, but the Action Menu does not appear. What are the top 3 causes?
> **Answer**:
> 1. The Action Menu is not attached to the form under **Form Properties $\rightarrow$ Context Menus**.
> 2. The user right-clicked a cell outside the grid or on an Excel POV cell (Smart View requires clicking within data cells).
> 3. The `Required Parameters` setting specifies a member or dimension that does not match cell `C10`.

#### Q17: You need to create an Action Menu item that allows users to calculate catering revenue only when they right-click department `D10010:Catering`. How do you configure this?
> **Answer**:
> 1. Set Type = **`Business Rule`**, select Cube = `FinPlan`, Rule = `Catering Revenue calculation`.
> 2. Set **`Required Parameters`** = **`Department`**.
> 3. In the **`Members`** field, use the member selector to pick `D10010`.
> 4. Save the menu item. It will now only appear when users right-click within Department `D10010`.

#### Q18: A Business Rule attached to an Action Menu fails with "Variable {Entity} not found in context". How do you fix this?
> **Answer**: Ensure the Runtime Prompt in Calculation Manager is named exactly matching the dimension name (`Entity`), or ensure the form has `Entity` on its Page, POV, Row, or Column axis so Context Relay can resolve the parameter.

#### Q19: Why are some menu items visible to Administrators but hidden from Planners?
> **Answer**: Planning enforces role-based artifact security. If a Planner does not have "Launch" permissions on the target Business Rule or "Read" access on the target Form, Planning automatically strips the menu item from that user's right-click menu.

#### Q20: What is the consultant checklist before promoting Action Menus to Production?
> **Answer**:
> 1. Verify all 9 menu items have explicit, non-overlapping `Required Parameters`.
> 2. Confirm `Hide Prompt` functions seamlessly without unexpected dialog popups.
> 3. Test flyout rendering in both Web Forms and Excel Smart View.
> 4. Verify artifact security permissions for all target rules, forms, and dashboards across user test groups.
> 5. Execute safe testing on `Copy Version` using sandbox targets to prevent data corruption.
